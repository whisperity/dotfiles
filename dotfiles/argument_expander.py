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
        Register that `key` appearing as an environment variable ($KEY) should
        be expanded to `value`.
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


def package_glob(available_packages, globbing_expr):
    """
    Performs a globbing of the given expression over the list of available
    names.

    Valid globbers are '*' and '__ALL__' as in "foo.*" which means "every
    package under foo".

    :return: The list of all packages globbed and expanded.
    """
    # Start out with everything that isn't a globbing expression:
    ret = set([normal for normal in globbing_expr
               if not normal.endswith(('*', '__ALL__'))])

    for name in set(globbing_expr) - ret:
        if not any(globstar in name
                   for globstar in ['.*', '.__ALL__']):
            raise ValueError("Please specify a tree with a closing . before "
                             "the * or __ALL__.")
        namespace = name.replace('.*', '', 1).replace('.__ALL__', '', 1)
        if '*' in namespace or '__ALL__' in namespace:
            raise ValueError("Do not specify multiple *s or __ALL__s in the "
                             "same tree name.")

        globbed_packages = [logical_name for logical_name in available_packages
                            if logical_name.startswith(namespace)]
        ret.update(globbed_packages)

    return ret


def deduplicate_iterable(it):
    """
    Deduplicates the elements in the given iterable by creating a new iterable
    in which the same element's first occurrence is kept.
    """
    seen = set()
    seen_add = seen.add
    return [x for x in it if not (x in seen or seen_add(x))]
