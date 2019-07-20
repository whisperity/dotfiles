import os
import shutil
import subprocess
import tempfile

from .common_shell import ShellCommands


class Prefetch(ShellCommands):
    """
    The prefetch stage is responsible for preparing the package for use, most
    often downloading external content or dependencies.
    """
    def __init__(self, package):
        self.package_name = package.name
        self._prefetch_dir = tempfile.mkdtemp('_' + package.name,
                                              "dotfiles-")

    @property
    def temp_path(self):
        return self._prefetch_dir

    def cleanup(self):
        """
        Executes the cleanup action for the instance.
        """
        def _onerror(func, path, exc_info):
            print("Error when cleaning up:")
            print(func, path, exc_info)
            print(":) Error ignored.")

        shutil.rmtree(self._prefetch_dir,
                      onerror=_onerror)

    def execute_command(self, action):
        name = action['kind'].replace(' ', '_')
        args = {k.replace(' ', '_'): action[k]
                for k in action
                if k != 'kind'}
        func = getattr(self, name)
        func(**args)

    def git_clone(self, remote):
        print("Cloning remote content from '%s'..."
              % remote)
        subprocess.call(['git', 'clone', remote,
                         '--origin', 'upstream',
                         '--depth', str(1)])

    def prompt_user(self, short_name, variable, description=None):
        print("\n-------- REQUESTING USER INPUT -------")
        print("Package '%s' requires you to provide '%s'"
              % (self.package_name, short_name))
        if 'description':
            print("    %s " % description)
        value = input(">> %s: " % short_name)

        with open(os.path.join(self._prefetch_dir,
                               'var-' + variable),
                  'w') as varfile:
            varfile.write(value)
        print("\n")
