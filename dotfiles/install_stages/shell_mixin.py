import subprocess


class ShellCommandsMixin:
    """
    Provides a set of commonly usable "execute shell command" actions for the
    installer.
    """

    def _expand(self, command):
        # The Shell mixin does not have variable expansion capability as a
        # hard requirement.
        expander = getattr(self, 'expand_args', None)
        if expander:
            command = expander(command)
        return command

    def shell(self, command):
        """
        Directly executes the command in the shell.
        """
        command = self._expand(command)
        returncode = subprocess.call(command, shell=True)
        return returncode == 0

    def shell_all(self, commands):
        """
        Directly execute all the given commands in the order they were given.
        """
        result = [self.shell(command) for command in commands]
        return all(result)

    def shell_any(self, commands):
        """
        Directly executes the given commands in the order they were given,
        until one of them succeeds.
        """
        for command in commands:
            if self.shell(command):
                return True

        return False
