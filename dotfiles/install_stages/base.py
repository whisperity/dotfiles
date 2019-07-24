
class _StageBase:
    """
    The base class from which all stage executors inherit from.
    """
    def __init__(self, for_package):
        self.package_name = for_package

    def __call__(self, kind, **kwargs):
        # TODO: Rename 'kind' to something more sensible.
        """
        Dispatch the actual execution of the action
        """
        kind = kind.replace(' ', '_')
        try:
            func = getattr(self, kind)
        except AttributeError:
            raise AttributeError("Invalid directive '%s' for package stage "
                                 "'%s'!" % (kind, type(self).__name__))

        args = {k.replace(' ', '_'): v for k, v in kwargs.items()}
        return func(**args)
