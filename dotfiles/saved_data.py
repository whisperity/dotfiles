from contextlib import contextmanager
from datetime import datetime
import json
import os
import zipfile

from .status import Status

_INSTANCE = None


def get_user_save():
    """
    Returns the current execution's instance for the user's configuration save
    file(s).
    """
    global _INSTANCE
    if not _INSTANCE:
        _INSTANCE = UserSave()
    return _INSTANCE


class UserSave:
    """
    The `UserSave` instance represents the persistent storage where the
    Dotfiles-specific user information, such as list of installed packages,
    is stored.
    """

    config_dir = os.path.join(os.path.expanduser('~'),
                              '.local', 'share', 'Dotfiles')
    state_file = os.path.join(config_dir, 'state.json')
    lock_file = os.path.join(config_dir, '.state.json.lock')

    def __init__(self):
        """
        Initialize the storage by loading the save from the user's disk.
        """

        # Handle a simple indicator lock on the state file.
        if os.path.exists(UserSave.lock_file):
            with open(UserSave.lock_file, 'r') as lock_fd:
                lock_pid = lock_fd.readline()
                raise PermissionError("The configuration state is locked "
                                      "by " + lock_pid)

        try:
            # Open the file normally.
            self._handle = open(UserSave.state_file, 'r+')
            self._lock_handle = open(UserSave.lock_file, 'w+')

            try:
                self._data = json.load(self._handle)
            except json.JSONDecodeError:
                self.close()
                raise
        except OSError:
            # If the file doesn't exist, create it.
            os.makedirs(os.path.dirname(UserSave.state_file), exist_ok=True)

            self._handle = open(UserSave.state_file, 'w+')
            self._lock_handle = open(UserSave.lock_file, 'w+')
            self._data = {
                'packages': {}
            }
            # Prepare the file to have a valid format.
            json.dump(self._data, self._handle)

        # Mark the state locked when the process starts running.
        self._lock_handle.write(".pid: " + str(os.getpid()) + '\n')
        self._lock_handle.flush()

        self._uncommitted_archives = {}

    def __del__(self):
        self.close()

    def close(self):
        """
        Gracefully flush status changes to disk, close the open resources
        and clear up.
        """
        if getattr(self, '_handle', None) and not self._handle.closed:
            if getattr(self, '_data', None):
                self._handle.seek(0)
                self._handle.truncate(0)
                json.dump(self._data, self._handle,
                          indent=None,
                          separators=(',', ':'))
            self._handle.close()

        if getattr(self, '_lock_handle', None):
            self._lock_handle.close()
            try:
                os.unlink(UserSave.lock_file)
            except FileNotFoundError:
                pass

    def is_installed(self, package_name):
        """
        :return: If the saved configuration has the package marked as
            installed.
        """
        return self._data['packages'].get(
            package_name, {'status': Status.NOT_INSTALLED.name})['status'] == \
            Status.INSTALLED.name

    def save_status(self, package):
        """
        Saves the status information of the given package to the user
        configuration.
        """
        pkg_dict = self._data['packages'].get(package.name, {})
        if not pkg_dict:
            self._data['packages'][package.name] = pkg_dict
        pkg_dict['status'] = package.status.name

        pkg_dict_st_changes = pkg_dict.get('latest_status_changes', {})
        if not pkg_dict_st_changes:
            pkg_dict['latest_status_changes'] = pkg_dict_st_changes
        pkg_dict_st_changes[package.status.name] = datetime.now().isoformat()

        try:
            pkg_dict['relevant_backup'] = os.path.basename(
                self._uncommitted_archives[package.name])
        except KeyError:
            # If a backup is not relevant, make sure the key is removed.
            try:
                del pkg_dict['relevant_backup']
            except KeyError:  # The key wasn't there.
                pass

    @property
    def installed_packages(self):
        """
        Generates the collection of packages that are considered installed.
        """
        for package, st_dict in self._data['packages'].items():
            if st_dict['status'] == Status.INSTALLED.name:
                yield package

    @contextmanager
    def get_package_archive(self, package_name):
        """
        Returns the `zipfile.ZipFile` context for the backup storage of the
        given `package`.

        If the package is not yet installed, a new archive will be created and
        it's context will be returned. (Multiple calls in the program to this
        function will return the same archive.)

        If the package has been installed, return the archive - if exists -
        that corresponds to the state of the most recent install.
        """
        if self.is_installed(package_name):
            mode = 'r'
            archive = os.path.join(
                UserSave.config_dir,
                self._data['packages'][package_name].get('relevant_backup'))
        else:
            mode = 'a'
            archive = self._uncommitted_archives.get(package_name)
            if not archive:
                print("Creating package archive for '%s'" % package_name)

                archive = os.path.join(UserSave.config_dir,
                                       package_name + '_' +
                                       datetime.now().strftime('%s') +
                                       '_0.zip')

                while os.path.isfile(archive):
                    # Unlikely, but the user might end up running the same
                    # installer in a quick succession, in which these archives
                    # could end up being filled multiple times.
                    archive = archive.split('_')
                    counter = int(archive[-1].replace('.zip', '', 1)) + 1
                    archive[-1] = str(counter) + '.zip'
                    archive = '_'.join(archive)

                self._uncommitted_archives[package_name] = archive

        zip_ = zipfile.ZipFile(archive, mode,
                               compression=zipfile.ZIP_DEFLATED)
        try:
            yield zip_
        finally:
            zip_.close()
