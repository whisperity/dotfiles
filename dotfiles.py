#!/usr/bin/env python3

import argparse
import fnmatch
import json
import os
import sys

if __name__ != "__main__":
    raise ImportError("Do not use this as a module.")

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

# Load the list of available packages.
script_directory = os.getcwd()
package_directory = os.path.join(script_directory, 'packages')

def file_to_packagename(packagefile):
    return os.path.dirname(packagefile) \
        .replace(package_directory, '') \
        .replace(os.sep, '.')           \
        .lstrip('.')


def packagename_to_file(packagename):
    return os.path.join(package_directory,
                        packagename.replace('.', os.sep),
                        'package.json')


package_files = [os.path.join(dirpath, f)
                for dirpath, dirnames, files in os.walk(package_directory)
                for f in fnmatch.filter(files, 'package.json')]
AVAILABLE_PACKAGES = [file_to_packagename(packagefile)
                      for packagefile in package_files]

if len(args.PACKAGE) == 0:
    print("Listing available packages...")

    for package in AVAILABLE_PACKAGES:
        print("    - %s" % package, end='')

        if package in PACKAGE_STATUS:
            print("       (%s)" % PACKAGE_STATUS[package], end='')

        with open(packagename_to_file(package), 'r') as packagefile:
            package_data = json.load(packagefile)
            print("        %s" % package_data['description'], end='')

        print()  # Linebreak.

    sys.exit(0)

# Run the package installs in topological order.
invalid_packages = [package for package in args.PACKAGE
                    if package not in AVAILABLE_PACKAGES]
if any(invalid_packages):
    print("ERROR: Specified to install packages that are not available!",
          file=sys.stderr)
    print("  Not found:  %s" % ', '.join(invalid_packages), file=sys.stderr)
    sys.exit(1)


def get_package_data(package):
    with open(packagename_to_file(package), 'r') as package_file:
        return json.load(package_file)


def is_installed(package):
    return package in PACKAGE_STATUS and PACKAGE_STATUS[package] == 'installed'


def check_dependencies(dependencies):
    unmet_dependencies = []

    for dependency in dependencies:
        if is_installed(dependency):
            print("  -| Dependency '%s' already met." % dependency)
            continue

        if dependency in unmet_dependencies:
            # Don't check a dependency one more time if we realised it is
            # unmet. The recursion should have had also found its
            # dependencies.
            continue

        print("  -> Checking dependency '%s'..." % dependency)
        dependency_data = get_package_data(dependency)
        if 'dependencies' in dependency_data and \
                any(dependency_data['dependencies']):
            unmet_dependencies.extend(
                check_dependencies(dependency_data['dependencies']))

        unmet_dependencies.append(dependency)

    return unmet_dependencies


def install_package(package):
    pass


# Check the depencies for the packages that the user wants to install.
WORK_QUEUE = []
for package in args.PACKAGE:
    # Check if the package is already installed. In this case, do nothing.
    if is_installed(package):
        print("%s is already installed -- skipping." % package)
        continue

    if package in WORK_QUEUE:
        # Don't check a package again if it was found as a dependency and the
        # user also specified it.
        continue

    print("Checking package '%s'..." % package)

    package_data = get_package_data(package)
    unmet_dependencies = []
    if 'dependencies' in package_data and any(package_data['dependencies']):
        unmet_dependencies = check_dependencies(package_data['dependencies'])
        if any(unmet_dependencies):
            print("Unmet dependencies for '%s': %s"
                  % (package, ', '.join(unmet_dependencies)))

    WORK_QUEUE = unmet_dependencies + [package] + WORK_QUEUE

while any(WORK_QUEUE):
    package = WORK_QUEUE[0]
    print("Preparing to install package '%s'..." % package)

    WORK_QUEUE = [p for p in WORK_QUEUE if p != package]
    install_package(package)

    PACKAGE_STATUS[package] = 'installed'

with open(os.path.join(os.path.expanduser('~'),
                           '.dotfiles'), 'w') as status:
        json.dump(PACKAGE_STATUS, status,
                  indent=2, sort_keys=True)
