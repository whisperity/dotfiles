import fnmatch
import json
import os

from dotfiles import install_stages
from dotfiles.argument_expander import ArgumentExpander
from dotfiles.chdir import restore_working_directory
from dotfiles.status import Status
from dotfiles.temporary import temporary_dir
from dotfiles.saved_data import get_user_save


class WrongStatusError(Exception):
    """
    Indicates that the package is in a wrong state to execute the required
    action.
    """
    def __init__(self, required_status, current_status):
        super().__init__()
        self._required = required_status
        self._current = current_status

    def __str__(self):
        return "Executing package action is invalid in status %s, as " \
               "%s is required." % (self._current, self._required)


class _StatusRequirementDecorator:
    """
    A custom decorator that can mark the requirement of a package state.
    """
    def __init__(self, *required_statuses):
        self.required = required_statuses

    def __call__(self, func):
        def _wrapper(*args):
            # Check the actual status of the object.
            instance = args[0]
            current_status = instance.__dict__['_status']

            if current_status not in self.required:
                print("Status failed, %s !€ %s"
                      % (current_status, self.required))
                import traceback
                traceback.print_exc()

                # TODO: Actually do the throw here.
                raise WrongStatusError(self.required, current_status)

            func(*args)
        return _wrapper


class Package:
    """
    Describes a package that the user can "install" to their system.

    Packages are stored in the 'packages/' directory in a hierarchy: directory
    names are translated as '.' separators in the logical package name.

    Each package MUST contain a 'package.json' file that describes the
    package's meta information and commands that are executed to configure and
    install the package.

    The rest of this package directory is ignored by the script.
    """

    # TODO: Support running the script from any folder, not just where
    #       it is checked out...
    package_directory = os.path.join(os.getcwd(), 'packages')

    @classmethod
    def package_name_to_data_file(cls, name):
        """
        Convert the package logical name to the datafile path.
        """
        return os.path.join(cls.package_directory,
                            name.replace('.', os.sep),
                            'package.json')

    @classmethod
    def data_file_to_package_name(cls, path):
        """
        Extract the name of the package from the file path of the package's
        metadata file.
        """
        return os.path.dirname(path) \
            .replace(cls.package_directory, '') \
            .replace(os.sep, '.') \
            .lstrip('.')

    def __init__(self, logical_name, datafile_path):
        self.name = logical_name
        self.datafile = datafile_path
        self.resources = os.path.dirname(datafile_path)
        self._status = Status.NOT_INSTALLED
        if get_user_save().is_installed(self.name):
            self._status = Status.INSTALLED

        self._teardown = []

        with open(datafile_path, 'r') as datafile:
            # TODO: Use YAML format instead of JSON.
            # TODO: Validate contents for action kinds and such.
            self._data = json.load(datafile)

        self._expander = ArgumentExpander()
        self._expander.register_expansion('PACKAGE_DIR', self.resources)
        self._expander.register_expansion('SESSION_DIR', temporary_dir())

    @classmethod
    def create(cls, logical_name):
        try:
            return Package(logical_name,
                           cls.package_name_to_data_file(logical_name))
        except FileNotFoundError:
            raise KeyError("Package data file for %s was not found.")

    @property
    def status(self):
        """
        Returns the `Status` value associated with the package.
        """
        return self._status

    @property
    def is_installed(self):
        return self._status == Status.INSTALLED

    @property
    def is_failed(self):
        return self._status == Status.FAILED

    @property
    def data(self):
        # TODO: DON'T EXPOSE THIS.
        return self._data

    @property
    def description(self):
        """
        An arbitrary description from the package metadata file that can be
        presented to the user.
        """
        return self._data.get('description', None)

    @property
    def is_support(self):
        """
        Whether or not a package is a "support package".

        Support packages are fully featured packages in terms of having prepare
        and install actions, but they are not meant to write anything permanent
        to the disk.

        Note that the Python code does NOT sanitise whether or not a package
        marked as a support package actually conforms to the rule above.
        """
        return self._data.get('support', False) or 'internal' in self.name

    @property
    def depends_on_parent(self):
        """
        Whether the package depends on its parent package in the logical
        hierarchy.
        """
        return self._data.get('depend_on_parent', True)

    @property
    def parent(self):
        """
        Returns the logical name of the package that SHOULD BE the parent
        package of the current one.

        There are no guarantees that the name actually refers to an
        installable package.
        """
        return '.'.join(self.name.split('.')[:-1])

    @property
    def dependencies(self):
        """
        Get the list of all dependencies the package metadata file describes.

        There are no guarantees that the packages named actually refer to
        installable packages.
        """
        return self._data.get('dependencies', []) + \
            ([self.parent] if self.depends_on_parent and self.parent
             else [])

    @_StatusRequirementDecorator(Status.NOT_INSTALLED)
    def select(self):
        """
        Mark the package selected for installation.
        """
        self._status = Status.MARKED

    def set_failed(self):
        """
        Mark that the package failed to install.
        """
        self._status = Status.FAILED

    @_StatusRequirementDecorator(Status.FAILED)
    def unselect(self):
        """
        Unmark the package from failure.
        """
        self._status = Status.NOT_INSTALLED

    @property
    def should_do_prepare(self):
        """
        :return: If there are pre-install actions present for the current
        package.
        """
        return self._status == Status.MARKED and \
            'prepare' in self._data

    @_StatusRequirementDecorator(Status.MARKED)
    @restore_working_directory
    def execute_prepare(self):
        if self.should_do_prepare:
            executor = install_stages.prepare.Prepare(self, self._expander)
            self._expander.register_expansion('TEMPORARY_DIR',
                                              executor.temp_path)

            self.prefetch_dir = executor.temp_path  # TODO: Remove.

            # Start the execution from the temporary download/prepare folder.
            os.chdir(executor.temp_path)

            for action in self._data.get('prepare'):
                executor.execute_command(action)

            # Register that temporary files were created and should be
            # cleaned up later.
            self._teardown.append(executor.cleanup)

        self._status = Status.PREPARED

    @_StatusRequirementDecorator(Status.PREPARED)
    @restore_working_directory
    def execute_install(self):
        executor = install_stages.install.Install(self, self._expander)

        # Start the execution in the package resource folder.
        os.chdir(self.resources)

        for action in self._data.get('install'):
            executor.execute_command(action)

        self._status = Status.INSTALLED

    def clean_temporaries(self):
        """
        Remove potential TEMPORARY files that were created during install
        from the system.
        """
        success = [f() for f in self._teardown]
        return all(success)

    def __str__(self):
        return self.name


def get_package_names(*roots):
    """
    Returns the logical name of packages that are available under the specified
    roots.
    """
    for root in roots:
        for dirpath, _, files in os.walk(root):
            for match in fnmatch.filter(files, 'package.json'):  # TODO: YAML
                yield Package.data_file_to_package_name(
                    os.path.join(dirpath, match))


def get_dependencies(package_store, package, ignore=None):
    """
    Calculate the logical names of the packages that are the dependencies of
    the given package instance.
    :param package_store: A dict of package instances that is the memory map of
        known packages.
    :param package: The package instance for whom the dependencies should be
        calculated.
    :param ignore: An optional list of package *NAMES* that should be ignored -
        if these packages are encountered, the dependency chain walk does not
        continue.
    """
    # This recursion isn't the fastest algorithm for creating dependencies,
    # but due to the relatively small size and scope of the project, this
    # will do.
    if package.name in ignore:
        return []
    if ignore is None:
        ignore = []

    dependencies = []
    for dependency in set(package.dependencies) - set(ignore):
        try:
            # Check if the dependency exists.
            dependency_obj = package_store[dependency]
        except KeyError:
            print(package.name, "dep", dependency, "par", package.parent)
            if dependency == package.parent:
                # Don't consider dependency on the parent an error if the
                # parent does not exist as a real package.
                pass

            raise KeyError("Dependency %s for %s was not found as a package."
                           % (dependency, package.name))

        # If the dependency exists as a package, it is a dependency.
        dependencies += [dependency]
        # And walk the dependencies of the now found dependency.
        dependencies.extend(get_dependencies(package_store,
                                             dependency_obj,
                                             ignore + [package.name]))

    return dependencies
