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

    def copy(self, to, file=None, files=None, prefix=''):
        """
        Copies one or multiple files from one place to another.

        This method is considered the unconditional copy, which inverse
        operation is the removal of a file.
        (For the version which can restore the version before the copy, see
        `overwrite` action.)

        If `file` is specified, it is an existing file, assumed to be relative
        to the current directory, if necessary.
        In this case, `to` is either the destination file path (cannot be
        relative), or the destination directory (cannot be relative) in which
        case the file's name will be retained.

        If `files` is specified, it is a list of files.
        In this case, `to` must be a destination directory, which must already
        exist.
        In this case, `prefix` may be specified, and it will be prepended to
        every destination file's name.
        """
        if file and files:
            raise NameError("Copy must specify either (file, to) or "
                            "(files, to).")
        if file and prefix:
            raise NameError("If only a single file is specified, use the 'to' "
                            "argument to specify the whole destination name!")

        to = self.expand_args(to)
        if os.path.abspath(to) != to:
            raise ValueError("'to' must be given as an absolute PATH")

        if files and not os.path.isdir(to):
            raise NotADirectoryError("'to' must be an existing directory when "
                                     "copying multiple files.")

        for file in (files if files else [file]):
            source = self.expand_args(file)
            target = to

            if prefix:
                target = os.path.join(to, os.path.basename(source))
                dirn, filen = os.path.split(target)
                target = os.path.join(dirn, prefix + filen)

            print("[DEBUG] Unconditionally copied '%s' to '%s'"
                  % (os.path.abspath(file), target))
            shutil.copy(file, target)

    def copy_tree(self, folder, to):
        # TODO: Revise this.
        from_folder = self.expand_args(folder)
        to_folder = self.expand_args(to)
        print("    ---> Copying folder '%s' to '%s'"
              % (from_folder, to_folder))
        shutil.copytree(from_folder, to_folder)

    def overwrite_(self, *l, **d):
        # TODO: Write this
        pass

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
