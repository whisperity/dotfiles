import os
import re
import shutil
import sys

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
