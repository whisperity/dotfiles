from enum import Enum


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
