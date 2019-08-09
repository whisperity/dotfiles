import fnmatch
import os
import pprint
import shutil
import zipfile

try:
    from yaml import YAMLError
    from yaml import load as load_yaml
    from yaml import dump as dump_yaml

    try:
        # Get the faster version of the loader, if possible.
        from yaml import CSafeLoader as Loader
        from yaml import CSafeDumper as Dumper
    except ImportError:
        # NOTE: Installing "LibYAML" requires compiling from source, so in
        # case the current environment does not have it, just fall back to
        # the pure Python (thus slower) implementation.
        from yaml import SafeLoader as Loader
        from yaml import SafeDumper as Dumper
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
from dotfiles.status import Status, require_status
from dotfiles.temporary import package_temporary_dir, temporary_dir


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


class PackageMetadataError(SystemError):
    """
    Indicates that a package's metadata 'package.yaml' file is semantically
    incorrect.
    """
    def __init__(self, package, msg):
        super().__init__()
        self.package = package
        self.msg = msg

    def __str__(self):
        return "%s 'package.yaml' invalid: %s" % (str(self.package), self.msg)


class Package:
    """
    Describes a package that the user can "install" to their system.

    Packages are stored in the 'packages/' directory in a hierarchy: directory
    names are translated as '.' separators in the logical package name.

    Each package MUST contain a 'package.yaml' file that describes the
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
            .replace(cls.package_directory, '', 1) \
            .replace(os.sep, '.') \
            .lstrip('.')

    def __init__(self, logical_name, datafile_path):
        self.name = logical_name
        self.datafile = datafile_path
        self.resource_dir = os.path.dirname(datafile_path)
        self._status = Status.NOT_INSTALLED

        # Optional callable, fetches resources. By default, not implemented.
        # (via https://stackoverflow.com/a/8294654)
        self._load_resources = lambda: (_ for _ in ()).throw(
            NotImplementedError("_load_resources wasn't specified."))

        self._teardown = []

        with open(datafile_path, 'r') as datafile:
            self._data = load_yaml(datafile, Loader=Loader)

        self._expander = ArgumentExpander()
        self._expander.register_expansion('PACKAGE_DIR', self.resource_dir)
        self._expander.register_expansion('SESSION_DIR', temporary_dir())

        # Validate package YAML structure.
        # TODO: This list of error cases is not full.
        if self.is_support and self.has_uninstall_actions:
            raise PackageMetadataError(self,
                                       "Package marked as a support but has "
                                       "an 'uninstall' section!")

    @classmethod
    def create(cls, logical_name):
        """
        Creates a `Package` instance for the given logical package name.
        """
        try:
            instance = Package(logical_name,
                               cls.package_name_to_data_file(logical_name))

            # A package loaded from the disk doesn't need anything extra
            # to load its resources.
            instance.__setattr__('_load_resources', lambda: None)

            return instance
        except FileNotFoundError:
            raise KeyError("Package data file for '%s' was not found."
                           % logical_name)
        except YAMLError:
            raise ValueError("Package data file for '%s' is corrupt."
                             % logical_name)

    @classmethod
    def create_from_archive(cls, logical_name, archive):
        """
        Creates a `Package` instance using the information and resources found
        in the given `archive` (which must be a `zipfile.ZipFile` instance).
        """
        if not isinstance(archive, zipfile.ZipFile):
            raise TypeError("'archive' must be a `ZipFile`")

        # Unpack the metadata file to a temporary directory.
        package_dir = package_temporary_dir(logical_name)
        archive.extract('package.yaml', package_dir)

        instance = Package(logical_name,
                           os.path.join(package_dir, 'package.yaml'))
        instance.__setattr__('_status', Status.INSTALLED)

        def _load_resources():
            """
            Helper function that will extract the resources of the package
            to the temporary directory when needed.
            """
            with zipfile.ZipFile(archive.filename, 'r') as zipf:
                for file in zipf.namelist():
                    if not file.startswith('$PACKAGE_DIR/'):
                        continue

                    zipf.extract(file, package_dir)

                    # Temporary is extracted by keeping the '$PACKAGE_DIR/'
                    # directory, thus it has to be moved one level up.
                    without_prefix = file.replace('$PACKAGE_DIR/', '', 1)
                    os.makedirs(
                        os.path.join(package_dir,
                                     os.path.dirname(without_prefix)),
                        exist_ok=True)
                    shutil.move(os.path.join(package_dir, file),
                                os.path.join(package_dir, without_prefix))
            shutil.rmtree(os.path.join(package_dir, '$PACKAGE_DIR'),
                          ignore_errors=True)

            # Subsequent calls to self._load_resources() shouldn't do anything.
            instance.__setattr__('_load_resources', lambda: None)

        instance.__setattr__('_load_resources', _load_resources)

        return instance

    @classmethod
    def save_to_archive(cls, package, archive):
        """
        Saves the given `package`'s resources(including the potential
        generated configuration) into the given `archive` (of type
        `zipfile.ZipFile`).
        """
        if not isinstance(archive, zipfile.ZipFile):
            raise TypeError("'archive' must be a `ZipFile`")

        for dirpath, _, files in os.walk(package.resource_dir):
            arcpath = dirpath.replace(package.resource_dir, '$PACKAGE_DIR', 1)
            if 'package.yaml' in files:
                package_name_for_yaml = \
                    Package.data_file_to_package_name(
                        os.path.join(dirpath, 'package.yaml'))
                if package_name_for_yaml != package.name:
                    # A subpackage was encountered, which should not be
                    # saved to the current package's archive.
                    continue

            for file in files:
                if file == 'package.yaml':
                    # Do not save 'package.yaml', the serialized memory
                    # will be saved instead.
                    continue

                archive.write(os.path.join(dirpath, file),
                              os.path.join(arcpath, file),
                              compress_type=zipfile.ZIP_DEFLATED)

        archive.writestr('package.yaml', package.serialize(),
                         compress_type=zipfile.ZIP_DEFLATED)

    @require_status(Status.NOT_INSTALLED, Status.INSTALLED)
    def serialize(self):
        """
        Return the package's data in YAML string format.
        """
        return dump_yaml(self._data)

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

    @require_status(Status.NOT_INSTALLED)
    def select(self):
        """
        Mark the package selected for installation.
        """
        self._status = Status.MARKED

    def set_failed(self):
        """
        Mark that the execution of package actions failed.
        """
        self._status = Status.FAILED

    @require_status(Status.FAILED)
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
        return 'prepare' in self._data

    @require_status(Status.MARKED)
    @restore_working_directory
    def execute_prepare(self):
        if self.should_do_prepare:
            executor = install_stages.prepare.Prepare(self, self._expander)
            self._expander.register_expansion('TEMPORARY_DIR',
                                              executor.temp_path)
            # Register that temporary files were created and should be
            # cleaned up later.
            self._teardown.append(getattr(executor, '_cleanup'))

            # Start the execution from the temporary download/prepare folder.
            os.chdir(executor.temp_path)

            self._load_resources()

            for step in self._data.get('prepare'):
                if not executor(**step):
                    self.set_failed()
                    raise ExecutorError(self, 'prepare', step)

        self._status = Status.PREPARED

    @require_status(Status.PREPARED)
    @restore_working_directory
    def execute_install(self):
        uninstall_generator = install_stages.uninstall.UninstallSignature()
        executor = install_stages.install.Install(self,
                                                  self._expander,
                                                  uninstall_generator)

        # Start the execution in the package resource folder.
        self._load_resources()
        os.chdir(self.resource_dir)

        for step in self._data.get('install'):
            if not executor(**step):
                self.set_failed()
                raise ExecutorError(self, 'install', step)

        self._status = Status.INSTALLED

        if uninstall_generator.actions:
            # Save the uninstall actions to the package's data.
            self._data['generated uninstall'] = \
                list(uninstall_generator.actions)

    @property
    def has_uninstall_actions(self):
        """
        :return: If there are uninstall actions present for the current
        package.
        """
        return 'uninstall' in self._data or \
            'generated uninstall' in self._data

    @require_status(Status.INSTALLED)
    @restore_working_directory
    def execute_uninstall(self):
        if self.has_uninstall_actions:
            executor = install_stages.uninstall.Uninstall(self, self._expander)

            # Start the execution in the package resource folder.
            self._load_resources()
            os.chdir(self.resource_dir)

            for step in (self._data.get('uninstall', []) +
                         self._data.get('generated uninstall', [])):
                if not executor(**step):
                    self.set_failed()
                    raise ExecutorError(self, 'uninstall', step)

        self._status = Status.NOT_INSTALLED

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
    if ignore is None:
        ignore = []
    if package.name in ignore:
        return []

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
