#!/usr/bin/env python3

import argparse
import atexit
from collections import deque
import json
import shutil
import subprocess
import sys
import textwrap

try:
    from tabulate import tabulate
except ImportError:
    import sys
    print("The tabulate package for the current Python interpreter cannot be "
          "loaded.\n"
          "Please run 'bootstrap.sh' from the directory of Dotfiles project "
          "to try and fix this.",
          file=sys.stderr)
    print("Will use a more ugly version of output tables as fallback...",
          file=sys.stderr)

    def tabulate(table, *args, **kwargs):
        """
        An ugly fallback for the table pretty-printer if 'tabulate' module is
        not available.
        """
        if 'headers' in kwargs:
            print('|', '        | '.join(kwargs['headers']), '       |')
        for row in table:
            for i, col in enumerate(row):
                row[i] = col.replace('\n', ' ')
            print('|', '        | '.join(row), '       |')

from dotfiles import argument_expander
from dotfiles import package
from dotfiles import temporary
from dotfiles.lazy_dict import LazyDict
from dotfiles.saved_data import get_user_save


if __name__ != "__main__":
    # This script is a user-facing entry point.
    raise ImportError("Do not use this as a module!")

PARSER = argparse.ArgumentParser(
    prog='dotfiles',
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description="""Installer program that handles installing user environment
                   configuration files and associated tools.""")

ACTION = PARSER.add_argument_group("action arguments")
ACTION = ACTION.add_mutually_exclusive_group()

ACTION.add_argument('-l', '--list',
                    dest='action',
                    action='store_const',
                    const='LIST',
                    default=False,
                    help="""Lists packages that could be installed from the
                            current repository, or are installed on the system
                            and could be uninstalled. This is the default
                            action if no package names are specified.""")

ACTION.add_argument('-i', '--install',
                    dest='action',
                    action='store_const',
                    const='INSTALL',
                    default=True,
                    help="""Installs the specified packages. This is the
                            default action if at least one package name is
                            specified.""")

ACTION.add_argument('-u', '--uninstall',
                    dest='action',
                    action='store_const',
                    const='REMOVE',
                    default=False,
                    help="""Uninstall the specified packages. (THIS IS NOT
                            WORKING YET!)""")

PARSER.add_argument('package_names',
                    nargs='*',
                    metavar='package',
                    type=str,
                    help="""The name of the packages that should be
                            (un)installed. All subpackages in a package group
                            can be selected by saying 'group.*'.""")

# TODO: Support multiple roots.

# TODO: Support not clearing temporaries for debug purposes.

# TODO: Verbosity switch?

ARGS = PARSER.parse_args()

# Handle the default case if the user did not specify an action.
if not isinstance(ARGS.action, str):
    if not ARGS.package_names:
        ARGS.action = 'LIST'
    else:
        ARGS.action = 'INSTALL'


# -----------------------------------------------------------------------------

try:
    # Load the persistent configuration.
    get_user_save()
except PermissionError:
    print("ERROR! Couldn't get lock on install information!", file=sys.stderr)
    print("Another Dotfiles install running somewhere?", file=sys.stderr)
    print("If not please execute: `rm -f %s` and try again."
          % get_user_save().lock_file, file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError:
    print("ERROR: User configuration file corrupted.", file=sys.stderr)
    print("It is now impossible to recover what packages were installed.",
          file=sys.stderr)
    print("Please remove configuration file with `rm %s` and try again."
          % get_user_save().state_file, file=sys.stderr)
    print("Every package will be considered never installed.", file=sys.stderr)
    sys.exit(1)


@atexit.register
def _clear_temporary_dir():
    if temporary.has_temporary_dir():
        shutil.rmtree(temporary.temporary_dir(), ignore_errors=True)


atexit.register(get_user_save().close)

# -----------------------------------------------------------------------------

# Load the names of available packages.
PACKAGES = LazyDict(package.Package.create)
for lname in package.get_package_names(package.Package.package_directory):
    # Indicate that for the name a package could be known, but hasn't been
    # instantiated yet.
    PACKAGES[lname] = None

if any(['internal' in name for name in ARGS.package_names]):
    print("'internal' a support package group that is not to be directly "
          "installed, its life is restricted to helping other packages' "
          "installation process!", file=sys.stderr)
    sys.exit(1)

PACKAGES_TO_INSTALL = deque(argument_expander.package_glob(PACKAGES.keys(),
                                                           ARGS.package_names))

# -----------------------------------------------------------------------------

# Handle printing the list of packages if the user didn't specify anything to
# install.
if ARGS.action == 'LIST':
    if not PACKAGES_TO_INSTALL:
        # If the user did not filter the packages to list, list everything.
        PACKAGES_TO_INSTALL = PACKAGES.keys()

    headers = ["St", "Package", "Description"]
    table = []
    for package_name in sorted(PACKAGES_TO_INSTALL):
        try:
            instance = PACKAGES[package_name]
        except KeyError:
            table.append(['???', package_name,
                          "ERROR: This package doesn't exist!"])
            continue

        if instance.is_support:
            continue

        status = 'ins' if instance.is_installed else ''

        # Make sure the description isn't too long.
        description = instance.description if instance.description else ''
        description = textwrap.fill(description, width=40)

        table.append([status, instance.name, description])

    print(tabulate(table, headers=headers, tablefmt='fancy_grid'))

    sys.exit(0)

# -----------------------------------------------------------------------------


def _die_for_invalid_packages():
    invalid_packages = [p for p in PACKAGES_TO_INSTALL if p not in PACKAGES]
    if invalid_packages:
        print("ERROR: Specified to install packages that are not available!",
              file=sys.stderr)
        print("  Not found:  %s" % ', '.join(invalid_packages),
              file=sys.stderr)
        sys.exit(1)


_die_for_invalid_packages()

# Check the dependencies of the packages the user wanted to install and create
# a sensible order of package installations.
for name in list(PACKAGES_TO_INSTALL):  # Work on copy of original input.
    instance = PACKAGES[name]
    if instance.is_support:
        print("%s a support package that is not to be directly installed, "
              "its life is restricted to helping other packages "
              "installation process!" % name, file=sys.stderr)
        sys.exit(1)

    # Check if the package is already installed. In this case, do nothing.
    if get_user_save().is_installed(name):
        print("%s is already installed -- skipping." % name)
        PACKAGES_TO_INSTALL.remove(name)
        continue

    unmet_dependencies = package.get_dependencies(
        PACKAGES, instance,
        list(get_user_save().installed_packages))
    if unmet_dependencies:
        print("%s needs dependencies to be installed: %s"
              % (name, ', '.join(unmet_dependencies)))
        PACKAGES_TO_INSTALL.extendleft(unmet_dependencies)

PACKAGES_TO_INSTALL = deque(
    argument_expander.deduplicate_iterable(PACKAGES_TO_INSTALL))
if not PACKAGES_TO_INSTALL:
    print("No packages need to be installed.")
    sys.exit(0)

print("Will install the following packages:\n        %s"
      % ' '.join(sorted(PACKAGES_TO_INSTALL)))


# -----------------------------------------------------------------------------


def check_superuser():
    print("Testing access to the 'sudo' command, please enter your password "
          "as prompted.",
          file=sys.stderr)
    print("If you don't have superuser access, please press Ctrl-D.",
          file=sys.stderr)

    try:
        res = subprocess.check_call(
            ['sudo', '-p', "[sudo] password for user '%p' for Dotfiles: ",
             'echo', "sudo check successful."])
        return not res
    except Exception as e:
        print("Checking 'sudo' access failed!", file=sys.stderr)
        print(str(e), file=sys.stderr)
        return False


HAS_SUPERUSER_CHECKED = None
for name in list(PACKAGES_TO_INSTALL):  # Work on copy as iteration modifies.
    instance = PACKAGES[name]
    if instance.requires_superuser:
        if HAS_SUPERUSER_CHECKED is None:
            print("Package '%s' requires superuser rights to install!" % name)
            HAS_SUPERUSER_CHECKED = check_superuser()  # Either True or False.

        if not HAS_SUPERUSER_CHECKED:  # Literal False.
            print("WARNING: Won't install '%s' as user presented no "
                  "superuser access!" % name, file=sys.stderr)
            instance.set_failed()


# -----------------------------------------------------------------------------
# Handle executing the actual install steps.
while PACKAGES_TO_INSTALL:
    print("--------------------========================---------------------")
    instance = PACKAGES[PACKAGES_TO_INSTALL.popleft()]

    # Check if any dependency of the package has failed to install.
    for dependency in instance.dependencies:
        try:
            d_instance = PACKAGES[dependency]
            if d_instance.is_failed:
                print("WARNING: Won't install '%s' as dependency '%s' "
                      "failed to install!"
                      % (instance.name, d_instance.name),
                      file=sys.stderr)
                # Cascade the failure information to all dependents.
                instance.set_failed()

                break  # Failure of one dependency is enough.
        except KeyError:
            # The dependency found by the name isn't a real package.
            # This can safely be ignored.
            pass

    if instance.is_failed:
        print("Skipping '%s'..." % instance.name)
        continue

    print("Selecting package '%s'" % instance.name)
    instance.select()

    if instance.should_do_prepare:
        print("Performing pre-installation steps for '%s'..."
              % instance.name)

    try:
        # (Prepare should always be called to advance the status of the
        # package even if it does not actions.)
        instance.execute_prepare()
    except Exception as e:
        print("Failed to prepare '%s' for installation!"
              % instance.name, file=sys.stderr)
        print(e)
        import traceback
        traceback.print_exc()

        instance.set_failed()
        continue

    try:
        print("Installing '%s'..." % instance.name)
        instance.execute_install()
    except Exception as e:
        print("Failed to install '%s'!"
              % instance.name, file=sys.stderr)
        print(e)
        import traceback

        traceback.print_exc()

        instance.set_failed()
        continue

    if instance.is_installed:
        print("Successfully installed '%s'." % instance.name)

        if not instance.is_support:
            # Save that the package was installed.
            get_user_save().save_status(instance)
