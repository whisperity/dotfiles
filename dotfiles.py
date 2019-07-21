#!/usr/bin/env python3

import argparse
import atexit
from collections import deque
import json
import shutil
import subprocess
import sys

from dotfiles import argument_expander
from dotfiles import package
from dotfiles import temporary
from dotfiles.lazy_dict import LazyDict
from dotfiles.saved_data import get_user_save


if __name__ != "__main__":
    raise ImportError("Do not use this as a module!")

parser = argparse.ArgumentParser(
    prog='dotfiles',
    description="Install work environment packages from this repository.")

parser.add_argument(
    'PACKAGE',
    nargs='*',
    type=str,
    help="The package name(s) to install. See the list of available packages "
         "by specifying no package names.")

args = parser.parse_args()

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

# -----------------------------------------------------------------------------

# Handle printing the list of packages if the user didn't specify anything to
# install.
# TODO: Make a better format for this.
if len(args.PACKAGE) == 0:
    print("Listing available packages...")

    for logical_name in PACKAGES:
        if 'internal' in logical_name:
            continue

        instance = PACKAGES[logical_name]
        print("    - %s" % instance.name, end='')

        if get_user_save().is_installed(instance.name):
            print("       (installed)", end='')

        if instance.description:
            print()  # Put a linebreak here too.
            print("          %s" % instance.description, end='')

        print()  # Linebreak.

    sys.exit(0)

# -----------------------------------------------------------------------------
# Sanitise user input.

if any(['internal' in name for name in args.PACKAGE]):
    print("'internal' a support package group that is not to be directly "
          "installed, its life is restricted to helping other packages' "
          "installation process!", file=sys.stderr)
    sys.exit(1)

PACKAGES_TO_INSTALL = deque(argument_expander.package_glob(PACKAGES.keys(),
                                                           args.PACKAGE))


def _die_for_invalid_packages():
    invalid_packages = [package for package in PACKAGES_TO_INSTALL
                        if package not in PACKAGES]
    if invalid_packages:
        print("ERROR: Specified to install packages that are not available!",
              file=sys.stderr)
        print("  Not found:  %s" % ', '.join(invalid_packages),
              file=sys.stderr)
        sys.exit(1)


_die_for_invalid_packages()


# -----------------------------------------------------------------------------

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
        print("Failed to prepare '%s' for installation!"
              % instance.name, file=sys.stderr)
        print(e)
        import traceback

        traceback.print_exc()

        instance.set_failed()
        continue

    if instance.is_installed:
        print("Successfully installed '%s'." % instance.name)

        # Save that the package was installed.
        get_user_save().save_status(instance)

    if not instance.clean_temporaries():
        print("Failed to clean installation temporaries for '%s'"
              % instance.name, file=sys.stderr)
