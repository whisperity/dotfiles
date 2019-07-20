from enum import Enum
import json
import os

from dotfiles.argument_expander import ArgumentExpander
from dotfiles.chdir import restore_working_directory
from dotfiles import install_stages


class Status(Enum):
    # The default state of a package.
    NOT_INSTALLED = 0,

    # The package is marked for installation, but dependencies prevent
    # installing just now.
    MARKED = 1,

    # The package is prepared for install: external dependencies and
    # configuration had been obtained.
    PREPARED = 2,

    # The package is installed.
    INSTALLED = 3,

    # TODO: Support uninstalling.


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
    def __init__(self, required_status):
        self.required = required_status

    def __call__(self, func):
        def _wrapper(*args):
            # Check the actual status of the object.
            instance = args[0]
            current_status = instance.__dict__['_status']

            if current_status != self.required:
                pass
                # TODO: Actually do the throw here.
                # raise WrongStatusError(self.required, current_status)

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
        self._status = Status.MARKED  # TODO: Implement dependency checking.
        self._teardown = []

        with open(datafile_path, 'r') as datafile:
            # TODO: Use YAML format instead of JSON.
            # TODO: Validate contents for action kinds and such.
            self._data = json.load(datafile)

        self._expander = ArgumentExpander()
        self._expander.register_expansion('PACKAGE_DIR',
                                          os.path.dirname(datafile_path))

    @classmethod
    def create(cls, logical_name):
        # TODO: Check if package is installed.
        return Package(logical_name,
                       cls.package_name_to_data_file(logical_name))

    def check_dependencies(self):
        """
        Check if the dependencies of the current package are satisfied.
        """
        # TODO: Implement this.
        raise NotImplementedError("TODO: Implement this.")

    @property
    def should_do_prepare(self):
        """
        :return: If there are pre-install actions present for the current
        package.
        """
        return self._status == Status.MARKED and \
            bool(self._data.get('prefetch', {}))

    @_StatusRequirementDecorator(Status.MARKED)
    @restore_working_directory
    def execute_prepare(self):
        # TODO: Rename the key in the scripts to "PREPARE".
        prefetch = self._data.get('prefetch', {})
        if prefetch:
            executor = install_stages.prepare.Prepare(self, self._expander)
            self._expander.register_expansion('PREFETCH_DIR',
                                              executor.temp_path)

            self.prefetch_dir = executor.temp_path  # TODO: Remove.

            # Start the execution from the temporary download/prepare folder.
            os.chdir(executor.temp_path)

            for action in prefetch:
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
