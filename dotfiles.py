#!/usr/bin/env python3

import argparse
from collections import deque
import json
import os
import shutil
import subprocess
import sys

from dotfiles import argument_expander
from dotfiles import package
from dotfiles import temporary
from dotfiles.lazy_dict import LazyDict


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

# Fetch what packages were marked installed for the user.
PACKAGE_STATUS = {}
try:
    with open(os.path.join(os.path.expanduser('~'),
                           '.dotfiles'), 'r') as status:
        PACKAGE_STATUS = json.load(status)
except OSError:
    print("Couldn't find local package status descriptor! Either missing, or "
          "first run?", file=sys.stderr)
except json.decoder.JSONDecodeError:
    print("Package status file is corrupt? Considering every package not "
          "installed.", file=sys.stderr)


# Load the names of available packages.
PACKAGES = LazyDict(package.Package.create)
for lname in package.get_package_names(package.Package.package_directory):
    # Indicate that for the name a package could be known, but hasn't been
    # instantiated yet.
    PACKAGES[lname] = None


# -----------------------------------------------------------------------------

# Handle printing the list of packages if the user didn't specify anything to
# install.
if len(args.PACKAGE) == 0:
    print("Listing available packages...")

    for logical_name in PACKAGES:
        if 'internal' in logical_name:
            continue

        instance = PACKAGES[logical_name]
        print("    - %s" % instance.name, end='')

        if instance.name in PACKAGE_STATUS:
            print("       (%s)" % PACKAGE_STATUS[instance.name], end='')

        if instance.description:
            print()  # Put a linebreak here too.
            print("          %s" % instance.description, end='')

        print()  # Linebreak.

    sys.exit(0)

# -----------------------------------------------------------------------------

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


def is_installed(package):
    return package in PACKAGE_STATUS and PACKAGE_STATUS[package] == 'installed'


# Check the dependencies of the packages the user wanted to install and create
# a sensible order of package installations.
for name in list(PACKAGES_TO_INSTALL):
    print("Checking package '%s'..." % name)
    instance = PACKAGES[name]
    if instance.is_support:
        print("%s a support package that is not to be directly installed, "
              "its life is restricted to helping other packages "
              "installation process!" % name, file=sys.stderr)
        sys.exit(1)

    # Check if the package is already installed. In this case, do nothing.
    if is_installed(name):  # TODO: This should be refactored too.
        print("%s is already installed -- skipping." % name)
        continue

    unmet_dependencies = package.get_dependencies(PACKAGES,
                                                  instance,
                                                  # TODO: Ignore already
                                                  #       installed.
                                                  list(PACKAGES_TO_INSTALL))

    if unmet_dependencies:
        print("Unmet dependencies for '%s': %s"
              % (name, ', '.join(unmet_dependencies)))

    PACKAGES_TO_INSTALL.extendleft(reversed(unmet_dependencies))

PACKAGES_TO_INSTALL = deque(
    argument_expander.deduplicate_iterable(PACKAGES_TO_INSTALL))
print("Will install the following packages:\n    %s"
      % ', '.join(PACKAGES_TO_INSTALL))


def check_superuser():
    print("Testing access to the 'sudo' command, please enter your password "
          "as prompted.")
    print("If you don't have superuser, please press Ctrl-D.")

    try:
        res = subprocess.check_call(
            ['sudo', 'echo', "Hello, dotfiles found 'sudo' rights. :-)"])
        return not res
    except Exception as e:
        print("Checking 'sudo' access failed.", file=sys.stderr)
        print(str(e), file=sys.stderr)
        return False


HAS_SUPERUSER_CHECKED = None
for name in PACKAGES_TO_INSTALL:
    package_data = PACKAGES[name].data

    if 'superuser' in package_data and not HAS_SUPERUSER_CHECKED:
        if package_data['superuser'] is True:
            print("Package '%s' requires superuser rights to install."
                  % name)
            test = check_superuser()
            if not test:
                print("ERROR: Can't install '%s' as user presented no "
                      "superuser access!" % name, file=sys.stderr)
                sys.exit(1)
            else:
                HAS_SUPERUSER_CHECKED = True


PACKAGE_TO_PREFETCH_DIR = {}


def install_package(package):
    package_data = PACKAGES[package].data
    if 'install' not in package_data:
        print("'%s' is a virtual package - no actions done." % package)
        return True

    package_instance = PACKAGES[package]

    if package_instance.should_do_prepare:
        print("Performing pre-installation steps for '%s'..."
              % package_instance.name)

        try:
            print("Executing prepare for", package_instance.name, "...")
            package_instance.execute_prepare()

            # TODO: This needs to be factored out.
            PACKAGE_TO_PREFETCH_DIR[package] = getattr(package_instance,
                                                       'prefetch_dir',
                                                       None)
        except Exception as e:
            print("Couldn't prepare '%s': '%s'!" % (package, e),
                  file=sys.stderr)
            print(e)

            import traceback
            traceback.print_exc()

            return False

    try:
        install_like_directive = 'install' if 'install' in package_data \
                                 else None
        if not install_like_directive:
            raise KeyError("Invalid state: package data for %s did not "
                           "contain any install-like directive?" % package)

        print("Executing installer for", package_instance.name, "...")
        package_instance.execute_install()
        return True
    except Exception as e:
        print("Couldn't install '%s': '%s'!" % (package, e), file=sys.stderr)
        print(e)

        import traceback
        traceback.print_exc()

        return False


while PACKAGES_TO_INSTALL:
    package_name = PACKAGES_TO_INSTALL.popleft()
    instance = PACKAGES[package_name]
    configure = instance.is_support
    print("Preparing to %s package '%s'..." %
          ('configure' if configure else 'install',
           package_name))

    success = install_package(package_name)
    if not success:
        print(" !! Failed to %s '%s'" %
              ('configure' if configure else 'install', package_name))
        PACKAGE_STATUS[package_name] = 'failed'
        break  # Explicitly break the loop and write the statuses.

    print("%s package '%s'." % ('Configured' if configure else 'Installed',
                                package_name))
    if not configure:
        PACKAGE_STATUS[package_name] = 'installed'

    success = PACKAGES[package_name].clean_temporaries()
    if not success:
        print(" !! Failed to clean up '%s'" % package_name)

if temporary.has_temporary_dir():
    print("Cleaning up installation temporaries...")
    shutil.rmtree(temporary.temporary_dir(), ignore_errors=True)

with open(os.path.join(os.path.expanduser('~'),
                       '.dotfiles'), 'w') as status:
    json.dump(PACKAGE_STATUS, status,
              indent=2, sort_keys=True)
