import os
import re
import shutil
import sys

from .base import _StageBase
from .shell_mixin import ShellCommandsMixin


class Install(_StageBase, ShellCommandsMixin):
    """
    The prefetch stage is responsible for preparing the package for use, most
    often downloading external content or dependencies.
    """
    def __init__(self, package, arg_expand):
        super().__init__(package)
        self.expand_args = arg_expand

    def make_dirs(self, dirs):
        """
        Creates the specified directories (and their parents if they don't
        exist).
        """
        # TODO: Uninstall equivalent: remove every directory if they are not
        #       empty, incl. all the parents created at this point.
        for dir in dirs:
            # Calculate which dirs would be created if they don't exist yet.
            path_parts = []
            head, tail = dir, ''
            while head:
                # Expand the environment variables only at expansion and not
                # for the iteration so we don't walk back up until /.
                path_parts.append(self.expand_args(head))
                head, tail = os.path.split(head)

            print("[DEBUG] Action tries creating dirs:", path_parts)

            os.makedirs(self.expand_args(dir), exist_ok=True)

        return True

    def extract_multiple(self, root, files):
        from_root_folder = root
        to_root_folder = os.path.expandvars('$' + root)
        print("    ---: Copying files from '%s' to '%s'"
              % (from_root_folder, to_root_folder))

        for f in files:
            print("       :- %s" % f)
            shutil.copy(os.path.join(from_root_folder, f),
                        os.path.join(to_root_folder, f))

    def copy(self, file, to):
        from_file = self.expand_args(file)
        to_file = self.expand_args(to)
        print("    ---> Copying file '%s' to '%s'"
              % (from_file, to_file))
        shutil.copy(from_file, to_file)

    def copy_tree(self, folder, to):
        from_folder = self.expand_args(folder)
        to_folder = self.expand_args(to)
        print("    ---> Copying folder '%s' to '%s'"
              % (from_folder, to_folder))
        shutil.copytree(from_folder, to_folder)

    def append(self, file, to):
        from_file = self.expand_args(file)
        to_file = self.expand_args(to)
        print("    ---> Appending package file '%s' to '%s'"
              % (from_file, to_file))
        with open(to_file, 'a') as to:
            with open(from_file, 'r') as in_file:
                to.write(in_file.read())

    def append_text(self, text, to):
        to_file = self.expand_args(to)
        print("    ---> Appending text to '%s'"
              % (to_file))
        with open(to_file, 'a') as to:
            to.write(text)
            to.write('\n')

    # TODO: Refactor user-given variables to be loaded from memory, not from
    #       a file.
    uservar_re = re.compile(r'\$<(?P<key>[\w_-]+)>',
                            re.MULTILINE | re.UNICODE)

    def __replace_uservar(self, match):
        var_name = match.group('key')
        try:
            with open(os.path.join(self.expand_args('$TEMPORARY_DIR'),
                                   'var-' + var_name),
                      'r') as varfile:
                value = varfile.read()

            return value
        except OSError:
            print("Error! Package requested to write user input to file "
                  "but no user input for variable '%s' was provide!"
                  % var_name,
                  file=sys.stderr)
            raise

    def __replace_envvar(self, match):
        var_name = match.group('key')
        value = os.environ.get(var_name)
        if not value:
            value = os.environ.get(var_name.lower())
        if not value:
            raise KeyError("Installer attempted to substitute environment "
                           "variable %s in script of %s but the variable is "
                           "not set." % (var_name, self.package_name))
        return value

    def replace_user_input(self, file):
        to_file = self.expand_args(file)
        print("    ---> Saving user configuration to '%s'" % to_file)
        with open(to_file, 'r+') as to:
            content = to.read()
            content = re.sub(self.uservar_re, self.__replace_uservar, content)
            to.seek(0)
            to.write(content)
            to.truncate(to.tell())

    def substitute_environment_variables(self, file):
        to_file = self.expand_args(file)
        print("    ---> Substituting environment vars in '%s'" % to_file)
        with open(to_file, 'r+') as to:
            content = to.read()
            content = re.sub(self.uservar_re, self.__replace_envvar, content)
            to.seek(0)
            to.write(content)
            to.truncate(to.tell())
