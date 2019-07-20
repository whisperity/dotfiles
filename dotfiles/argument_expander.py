import os


class ArgumentExpander:
    def __init__(self, expand_environment=True):
        """
        :param expand_environment: If True, environment variables of the
            interpreter (such as $USER, $HOME, etc.) will also be expanded.
        """
        self._envs = {}
        self._expand_environ = expand_environment

    def register_expansion(self, key, value):
        """
        Register that 'key' appearing as an environment variable ($KEY) should
        be expanded to 'value'.
        """
        self._envs[key] = value

    def __call__(self, *args):
        ret = []
        for arg in args:
            for enkey, enval in self._envs.items():
                arg = arg.replace('$%s' % enkey, enval)

            if self._expand_environ:
                arg = os.path.expandvars(arg)

            ret.append(arg)

        return ret[0] if len(ret) == 1 else ret
