from functools import wraps
import os


def restore_working_directory(fun):
    """
    Provides a method decorator that will restore the working directory of
    the executing Python interpreter to whatever it was when the method started
    executing.
    """
    @wraps(fun)
    def _wrapper(*args, **kwargs):
        cwd = os.getcwd()
        ret = fun(*args, **kwargs)
        os.chdir(cwd)
        return ret
    return _wrapper
