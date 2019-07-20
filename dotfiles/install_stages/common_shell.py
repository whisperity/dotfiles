import subprocess


class ShellCommands:
    """
    Provides a set of commonly usable "execute shell command" actions for the
    installer.
    """

    def _expand(self, command):
        expander = getattr(self, 'expand_args', None)
        if expander:
            command = expander(command)
        return command

    def shell(self, command):
        print(command)

        command = self._expand(command)

        print("Executing command-line: ", command)

        returncode = subprocess.call(command,
                                     shell=True)

        return returncode == 0

    def shell_tryinorder(self, commands):
        for command in commands:
            success = self.shell(command)
            if success:
                break

    def shell_multiple(self, commands):
        for command in commands:
            self.shell(command)
