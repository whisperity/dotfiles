from collections import deque
from functools import wraps
import inspect

from .base import _StageBase
from .shell_mixin import ShellCommandsMixin


class Uninstall(_StageBase, ShellCommandsMixin):
    """
    The uninstall stage is responsible for clearing the package from the
    system, preferably to a state as if it was never installed.
    """
    def __init__(self, package, arg_expand):
        super().__init__(package)
        self.expand_args = arg_expand


def _wrap(fun):
    """
    Wraps the executed function with the action store logic for
    `_UninstallSignature`.
    """
    @wraps(fun)
    def _wrapper(*args, **kwargs):
        # Save the action's invocation.
        bind = inspect.signature(fun).bind(*args, **kwargs).arguments
        save_args = {k: bind[k]
                for k in filter(lambda k: k != 'self', bind)}
        save_args['action'] = fun.__name__
        bind['self'].register_action(**save_args)

        return fun(*args, **kwargs)
    return _wrapper


class UninstallSignature:
    """
    `Uninstall` but without actually executing anything. This is used to store
    the uninstall actions that are automatically generated during installation
    of a package.
    """
    def __init__(self):
        self.actions = deque()

    def register_action(self, **kwargs):
        """
        Saves the specifed action to the stack of actions to be executed at
        uninstall.
        """
        args = {k.replace(' ', '_'): v for k, v in kwargs.items()}
        self.actions.appendleft(args)

    # Developer note: keep the methods from `Uninstall` in sync without a body!
