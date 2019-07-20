#!/usr/bin/env python3

import argparse
import fnmatch
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

from dotfiles import install_stages
from dotfiles.package import Package


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
# FIXME: This doesn't work when the current directory isn't the checkout
#        directory of the project.
script_directory = os.getcwd()
package_directory = Package.package_directory  # TODO: Delete this.


def file_to_packagename(packagefile):
    # TODO: Remove this.
    return Package.data_file_to_package_name(packagefile)


def packagename_to_file(packagename):
    # TODO: Remove this.
    return Package.package_name_to_data_file(packagename)


def get_package_data(package):
    with open(packagename_to_file(package), 'r') as package_file:
        return json.load(package_file)


package_files = [os.path.join(dirpath, f)
                 for dirpath, dirnames, files in os.walk(package_directory)
                 for f in fnmatch.filter(files, 'package.json')]
AVAILABLE_PACKAGES = [file_to_packagename(packagefile)
                      for packagefile in package_files]

if len(args.PACKAGE) == 0:
    print("Listing available packages...")

    for package in AVAILABLE_PACKAGES:
        if package.startswith('internal'):
            continue

        package_data = get_package_data(package)

        print("    - %s" % package, end='')

        if package in PACKAGE_STATUS:
            print("       (%s)" % PACKAGE_STATUS[package], end='')

        if 'description' in package_data:
            print()  # Put a linebreak here too.
            print("          %s" % package_data['description'], end='')

        print()  # Linebreak.

    sys.exit(0)

# Translate globber expressions such as "foo.bar.*" into actual package list.
specified_packages = args.PACKAGE[:]
args.PACKAGE = []
for package in specified_packages:
    if not package.endswith(('*', '__ALL__')):
        args.PACKAGE.append(package)
        continue

    namespace = package.replace('*', '').replace('__ALL__', '')
    if namespace.startswith('internal'):
        print("%s a configuration package group that is not to be installed, "
              "it's life is restricted to helping another package's "
              "installation process!" % package, file=sys.stderr)
        sys.exit(1)

    globbed_packages = [package for package in AVAILABLE_PACKAGES
                        if package.startswith(namespace) and
                        not package.startswith('internal')]
    for package in globbed_packages:
        print("Marked '%s' for installation." % package)

    # Update the remaining package list to include all the marked packages.
    args.PACKAGE = args.PACKAGE + globbed_packages

del specified_packages

# Run the package installs in topological order.
invalid_packages = [package for package in args.PACKAGE
                    if package not in AVAILABLE_PACKAGES]
if any(invalid_packages):
    print("ERROR: Specified to install packages that are not available!",
          file=sys.stderr)
    print("  Not found:  %s" % ', '.join(invalid_packages), file=sys.stderr)
    sys.exit(1)


def add_parent_package_as_dependency(package, package_data):
    if 'depend_on_parent' in package_data and \
            not package_data['depend_on_parent']:
        # Don't add as a dependency if the current package is explicitly
        # marked not to have their parent as a dependency.
        return

    try:
        parent_name = '.'.join(package.split('.')[:-1])
        get_package_data(parent_name)
    except (IndexError, OSError):
        # The parent is not a package, don't do anything.
        return

    if 'dependencies' not in package_data:
        package_data['dependencies'] = []

    if parent_name not in package_data['dependencies']:
        print("  -< Automatically marked parent '%s' as dependency."
              % parent_name)
        package_data['dependencies'] = \
            [parent_name] + package_data['dependencies']


def is_installed(package):
    return package in PACKAGE_STATUS and PACKAGE_STATUS[package] == 'installed'


def is_configuration_package(package):
    # TODO: "configuration" packages are broken in the current state.
    # QUESTION: Do we need this notion of configuration packages, even?
    return get_package_data(package).get('configuration', False)


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
        add_parent_package_as_dependency(dependency, dependency_data)
        if 'dependencies' in dependency_data and \
                any(dependency_data['dependencies']):
            unmet_dependencies.extend(
                check_dependencies(dependency_data['dependencies']))

        unmet_dependencies.append(dependency)

    return unmet_dependencies


# Check the depencies for the packages that the user wants to install.
WORK_QUEUE = []

for package in args.PACKAGE:
    print("Checking package '%s'..." % package)
    package_data = get_package_data(package)

    if is_configuration_package(package):
        print("%s a configuration package that is not to be installed, "
              "it's life is restricted to helping another package's "
              "installation process!" % package, file=sys.stderr)
        sys.exit(1)

    # Check if the package is already installed. In this case, do nothing.
    if is_installed(package):
        print("%s is already installed -- skipping." % package)
        continue

    if package in WORK_QUEUE:
        # Don't check a package again if it was found as a dependency and the
        # user also specified it.
        continue

    add_parent_package_as_dependency(package, package_data)
    unmet_dependencies = []
    if 'dependencies' in package_data and any(package_data['dependencies']):
        unmet_dependencies = check_dependencies(package_data['dependencies'])
        if any(unmet_dependencies):
            print("Unmet dependencies for '%s': %s"
                  % (package, ', '.join(unmet_dependencies)))

    WORK_QUEUE = WORK_QUEUE + unmet_dependencies + [package]


# Preparation and cleanup steps before actual install.
def deduplicate_work_queue():
    seen = set()
    seen_add = seen.add
    return [x for x in WORK_QUEUE if not (x in seen or seen_add(x))]


WORK_QUEUE = deduplicate_work_queue()
print("Will install the following packages:\n    %s" % ', '.join(WORK_QUEUE))


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
for package in WORK_QUEUE:
    package_data = get_package_data(package)

    if 'superuser' in package_data and not HAS_SUPERUSER_CHECKED:
        if package_data['superuser'] is True:
            print("Package '%s' requires superuser rights to install."
                  % package)
            test = check_superuser()
            if not test:
                print("ERROR: Can't install '%s' as user presented no "
                      "superuser access!" % package, file=sys.stderr)
                sys.exit(1)
            else:
                HAS_SUPERUSER_CHECKED = True


PACKAGE_TO_PREFETCH_DIR = {}
PACKAGES = {}


def _load_package(package_name):
    # TODO: Refactor this to be on the top and loaded in advance.
    package = PACKAGES.get(package_name, None)
    if not package:
        package = Package.create(package_name)
        PACKAGES[package_name] = package
    return package


def install_package(package):
    package_data = get_package_data(package)
    if 'install' not in package_data:
        print("'%s' is a virtual package - no actions done." % package)
        return True

    package_instance = _load_package(package)

    if package_instance.should_do_prepare:
        print("Performing pre-installation steps for '%s'..."
              % package_instance.name)

        try:
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

        package_instance.execute_install()
        return True
    except Exception as e:
        print("Couldn't install '%s': '%s'!" % (package, e), file=sys.stderr)
        print(e)

        import traceback
        traceback.print_exc()

        return False


CLEANUP_PACKAGES = []
while any(WORK_QUEUE):
    package = WORK_QUEUE[0]

    configure = is_configuration_package(package)
    print("Preparing to %s package '%s'..." %
          ('configure' if configure else 'install',
           package))

    WORK_QUEUE = [p for p in WORK_QUEUE if p != package]

    success = install_package(package)
    if not success:
        print(" !! Failed to %s '%s'" %
              ('configure' if configure else 'install', package))
        PACKAGE_STATUS[package] = 'failed'
        break  # Explicitly break the loop and write the statuses.

    print("%s package '%s'." % ('Configured' if configure else 'Installed',
                                package))
    if not configure:
        PACKAGE_STATUS[package] = 'installed'

    CLEANUP_PACKAGES.append(package)

    with open(os.path.join(os.path.expanduser('~'),
                           '.dotfiles'), 'w') as status:
        json.dump(PACKAGE_STATUS, status,
                  indent=2, sort_keys=True)


def cleanup_package(package):
    package_data = get_package_data(package)
    if 'cleanup' not in package_data:
        print("'%s' is an install package - no actions done." % package)
        return True

    package_dir = os.path.dirname(packagename_to_file(package))
    prefetch_dir = PACKAGE_TO_PREFETCH_DIR.get(package, None)

    def __expand(path):
        """
        Helper method for expanding not only the environment variables in an
        install action, but script-specific variables.
        """

        if '$PREFETCH_DIR' in path:
            if not prefetch_dir:
                raise ValueError("Invalid directive: '$PREFETCH_DIR' used "
                                 "without any prefetch command executed.")
            path = path.replace('$PREFETCH_DIR', prefetch_dir)

        path = path.replace('$SCRIPT_DIR', script_directory)
        path = path.replace('$PACKAGE_DIR', package_dir)
        path = os.path.expandvars(path)

        return path

    def __exec_shell(cmdline):
        """
        Executes a "shell" action of a package. Returns whether the return code
        of the command was 0 (success).
        """
        if isinstance(cmdline, str):
            cmdline = [cmdline]

        cmdline = [__expand(c) for c in cmdline]
        retcode = subprocess.call(cmdline, shell=True)
        return retcode == 0

    if 'cleanup' in package_data:
        print("Performing extra cleanup steps after usage of '%s'..." %
              package)

        try:
            # TODO: This part of the toolchain should be reconsidered.

            # execute_prepare_actions(package,
            #                         package_data['cleanup'],
            #                         __expand,
            #                         __exec_shell)
            return True
        except Exception as e:
            print("Couldn't clean up '%s': '%s'!" % (package, e),
                  file=sys.stderr)
            print(e)
            return False
        finally:
            os.chdir(script_directory)


for package in CLEANUP_PACKAGES:
    print("Cleaning up package '%s'..." % package)
    success = cleanup_package(package)

    package_instance = _load_package(package)
    package_instance.clean_temporaries()

    if not success:
        print(" !! Failed to clean up '%s'" % package)
