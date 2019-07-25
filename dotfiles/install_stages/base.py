
class _StageBase:
    """
    The base class from which all stage executors inherit from.
    """
    def __init__(self, package):
        self.package = package

    def __call__(self, action, **kwargs):
        """
        Dispatch the actual execution of the action
        """
        if action.startswith('_'):
            raise AttributeError("Invalid action '%s' requested: do not try "
                                 "accessing execution engine internals!"
                                 % action)

        action = action.replace(' ', '_')
        try:
            func = getattr(self, action)
        except AttributeError:
            raise AttributeError("Invalid action '%s' for package stage "
                                 "'%s'!" % (action, type(self).__name__))

        args = {k.replace(' ', '_'): v for k, v in kwargs.items()}

        ret = func(**args)
        if ret is None:
            # Assume true if the function didn't return anything.
            ret = True
        return ret
