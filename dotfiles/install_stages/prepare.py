import os
import shutil
import subprocess

from dotfiles.temporary import package_temporary_dir
from .base import _StageBase
from .shell_mixin import ShellCommandsMixin


class Prepare(_StageBase, ShellCommandsMixin):
    """
    The prefetch stage is responsible for preparing the package for use, most
    often downloading external content or dependencies.
    """
    def __init__(self, package, arg_expand):
        super().__init__(package)
        self._prefetch_dir = package_temporary_dir(package.name)
        self.expand_args = arg_expand

    @property
    def temp_path(self):
        return self._prefetch_dir

    def _cleanup(self):
        """
        Executes the cleanup action for the instance.
        """
        def _onerror(func, path, exc_info):
            print("Error when cleaning up:")
            print(func, path, exc_info)
            print(":) Error ignored.")

        shutil.rmtree(self.temp_path,
                      onerror=_onerror)

        return True

    # The prepare stage has no "uninstall equivalents" as prepare actions are
    # supposed to write to the disk only in the temporary directory, which is
    # cleaned up automatically.

    def copy_resource(self, path):
        """
        Copies a resource (a file or directory that is shipped together with
        the package's metadata) to the temporary directory.

        `path` is considered relative to the package's source directory, and
        MUST NOT lead out of it. On the destination side, the output file will
        be on the same path, relative to the temporary directory.
        """
        source_path = os.path.abspath(
            os.path.join(self.package.resource_dir, path))
        common_prefix = os.path.commonprefix([
            os.path.abspath(self.package.resource_dir),
            source_path])
        if common_prefix != os.path.abspath(self.package.resource_dir):
            raise PermissionError("Specifying a path outside the resource "
                                  "directory is forbidden.")

        relative_path = os.path.relpath(source_path, self.package.resource_dir)
        target_path = os.path.join(self.temp_path, relative_path)
        if os.path.abspath(target_path) == os.path.abspath(self.temp_path):
            raise PermissionError("Resource-copying the entire package "
                                  "directory is forbidden.")

        target_parent = os.path.dirname(target_path)
        if not os.path.isdir(target_parent):
            os.makedirs(target_parent, exist_ok=True)

        if os.path.isfile(source_path):
            shutil.copy(source_path, target_path)
        elif os.path.isdir(source_path):
            shutil.copytree(source_path, relative_path)
        else:
            raise FileNotFoundError("Invalid path '%s', no such file exists "
                                    "relative to '%s'"
                                    % (path, self.package.resource_dir))

    def git_clone(self, repository):
        """
        Obtain a shallow Git clone of a remote repository.
        """
        try:
            ret = subprocess.call(['git', 'clone', repository,
                                   '--origin', 'upstream',
                                   '--depth', str(1)])
            return ret == 0
        except subprocess.CalledProcessError:
            print("Git clone for '%s' failed." % repository)
            return False

    # TODO: Add a shortcut action for "wget/curl file -> untar/unzip -> rename"

    def prompt_user(self, short_name, variable, description=None):
        # TODO: Refactor this to not write to a file but have a
        #       'configuration' part of the package.
        print("\n-------- REQUESTING USER INPUT -------")
        print("Package '%s' requires you to provide '%s'"
              % (self.package.name, short_name))
        if 'description':
            print("    %s " % description)
        value = input(">> %s: " % short_name)

        with open(os.path.join(self._prefetch_dir,
                               'var-' + variable),
                  'w') as varfile:
            varfile.write(value)
        print("\n")
