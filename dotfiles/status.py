from enum import Enum
from functools import wraps


class Status(Enum):
    # The default state of a package.
    NOT_INSTALLED = 0,

    # The package is marked for installation.
    MARKED = 1,

    # The package is prepared for install: external dependencies and
    # configuration had been obtained.
    PREPARED = 2,

    # The package is installed.
    INSTALLED = 3,

    # Installing the package has failed and thus the contents were not
    # installed properly.
    FAILED = 99


class WrongStatusError(Exception):
    """
    Indicates that the package is in a wrong state to execute the required
    action.
    """
    def __init__(self, required_status, current_status):
        super().__init__()
        self.required = required_status
        self.current = current_status

    def __str__(self):
        return "Executing package action is invalid in status %s, as " \
               "%s is required." % (self.current, self.required)


def require_status(*required_statuses):
    """
    Decorates a method of a class having a `status` attribute so that calling
    a method when the `status` isn't one of the given `required_statuses`, a
    `WrongStatusError` will be raised.
    """
    def _decorator(fun):
        @wraps(fun)
        def _wrapper(*args, **kwargs):
            # Check the actual status of the object.
            instance = args[0]
            current_status = instance.__dict__['_status']

            if current_status not in required_statuses:
                raise WrongStatusError(required_statuses, current_status)

            return fun(*args, **kwargs)
        return _wrapper
    return _decorator
