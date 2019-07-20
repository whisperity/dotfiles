import os


class restore_working_directory:
    """
    Provides a method decorator that will restore the working directory of
    the executing Python interpreter to whatever it was when the method started
    executing.
    """
    def __init__(self, func):
        self._func = func

    def __call__(self, *args, **kwargs):
        cwd = os.getcwd()

        self._func(*args, **kwargs)

        os.chdir(cwd)
