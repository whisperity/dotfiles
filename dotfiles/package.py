import fnmatch
import os
import pprint

try:
    from yaml import YAMLError
    from yaml import load as load_yaml

    try:
        # Get the faster version of the loader, if possible.
        from yaml import CSafeLoader as Loader
    except ImportError:
        # NOTE: Installing "LibYAML" requires compiling from source, so in
        # case the current environment does not have it, just fall back to
        # the pure Python (thus slower) implementation.
        from yaml import SafeLoader as Loader
except ImportError:
    import sys
    print("The YAML package for the current Python interpreter cannot be "
          "loaded.\n"
          "Please run 'bootstrap.sh' from the directory of Dotfiles project "
          "to try and fix this error.",
          file=sys.stderr)
    sys.exit(-1)

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
        self.required = required_status
        self.current = current_status

    def __str__(self):
        return "Executing package action is invalid in status %s, as " \
               "%s is required." % (self.current, self.required)


class ExecutorError(Exception):
    """
    Indicates that an error happened during execution of a command from the
    package descriptor.
    """
    def __init__(self, package, stage, action):
        super().__init__()
        self.package = package
        self.stage = stage
        self.action = action

    def __str__(self):
        return "Execution of %s action for %s failed.\n" \
               "Details of action:\n%s" \
               % (self.stage, str(self.package), pprint.pformat(self.action))


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
                            'package.yaml')

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
            # TODO: Validate contents for action kinds and such.
            self._data = load_yaml(datafile, Loader=Loader)

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
        except YAMLError:
            raise ValueError("Package data file for '%s' is corrupt."
                             % logical_name)

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
    def description(self):
        """
        An arbitrary description from the package metadata file that can be
        presented to the user.
        """
        return self._data.get('description', None)

    @property
    def requires_superuser(self):
        """
        Returns whether or not installing the package requires superuser
        access.
        """
        return self._data.get('superuser', False)

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
            # Register that temporary files were created and should be
            # cleaned up later.
            self._teardown.append(executor.cleanup)

            # Start the execution from the temporary download/prepare folder.
            os.chdir(executor.temp_path)

            for step in self._data.get('prepare'):
                if not executor(**step):
                    self.set_failed()
                    raise ExecutorError(self, 'prepare', step)

        self._status = Status.PREPARED

    @_StatusRequirementDecorator(Status.PREPARED)
    @restore_working_directory
    def execute_install(self):
        executor = install_stages.install.Install(self, self._expander)

        # Start the execution in the package resource folder.
        os.chdir(self.resources)

        for step in self._data.get('install'):
            if not executor(**step):
                self.set_failed()
                raise ExecutorError(self, 'install', step)

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
            for match in fnmatch.filter(files, 'package.yaml'):
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
            if dependency == package.parent:
                # Don't consider dependency on the parent an error if the
                # parent does not exist as a real package.
                continue

            raise KeyError("Dependency %s for %s was not found as a package."
                           % (dependency, package.name))

        # If the dependency exists as a package, it is a dependency.
        dependencies += [dependency]
        # And walk the dependencies of the now found dependency.
        dependencies.extend(get_dependencies(package_store,
                                             dependency_obj,
                                             ignore + [package.name]))

    return dependencies
