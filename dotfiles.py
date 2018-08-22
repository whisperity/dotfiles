#!/usr/bin/env python3

import argparse
import fnmatch
import json
import os
import shutil
import subprocess
import sys
import tempfile

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
            print()  # Put a linebreak here too.
            print("          %s" % package_data['description'], end='')

        print()  # Linebreak.

    sys.exit(0)

# Translate globber expressions such as "foo.bar.*" into actual package list
for all_marker in [package for package in args.PACKAGE
                   if package.endswith('*') or package.endswith('__ALL__')]:
    namespace = all_marker.replace('*', '').replace('__ALL__', '')

    packages = [package for package in AVAILABLE_PACKAGES
                if package.startswith(namespace)]
    for package in packages:
        print("Marked '%s' for installation." % package)

    # Update the remaining package list to include all the marked packages.
    args.PACKAGE = packages + [package for package in args.PACKAGE
                               if package != all_marker]

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
    package_data = get_package_data(package)
    if 'install' not in package_data:
        print("'%s' is a virtual package - no install actions done." % package)
        return True

    prefetch_dir = None
    if 'prefetch' in package_data:
        print("Obtaining extra content for install of '%s'..." % package)

        # Create a temporary directory for this operation
        prefetch_dir = tempfile.mkdtemp(None, "dotfiles-")

        try:
            os.chdir(prefetch_dir)

            for command in package_data['prefetch']:
                kind = command['kind']
                if kind == 'git clone':
                    print("Cloning remote content from '%s'..."
                          % command['remote'])
                    subprocess.call(['git', 'clone', command['remote'],
                                     '--origin', 'upstream',
                                     '--depth', str(1)])
        except Exception as e:
            print("Couldn't fetch '%s': '%s'!" % (package, e),
                  file=sys.stderr)
            print(e)
            return False
        finally:
            os.chdir(script_directory)


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
        return os.path.expandvars(path)


    try:
        os.chdir(os.path.dirname(packagename_to_file(package)))

        for command in package_data['install']:
            kind = command['kind']
            if kind == 'shell':
                subprocess.call(command['command'], shell=True)
            elif kind == 'make folders':
                for folder in command['folders']:
                    output = os.path.expandvars(folder)
                    print("    ---\ Creating output folder '%s'" % output)
                    os.makedirs(output)
            elif kind == 'extract multiple':
                from_root_folder = command['root']
                to_root_folder = os.path.expandvars('$' + command['root'])
                print("    ---: Copying files from '%s' to '%s'"
                      % (from_root_folder, to_root_folder))

                for f in command['files']:
                    print("       :- %s" % f)
                    shutil.copy(os.path.join(from_root_folder, f),
                                os.path.join(to_root_folder, f))
            elif kind == 'copy':
                from_file = __expand(command['file'])
                to_file = os.path.expandvars(command['to'])
                print("    ---> Copying file '%s' to '%s'"
                      % (from_file, to_file))
                shutil.copy(from_file, to_file)
            elif kind == 'copy tree':
                from_folder = __expand(command['folder'])
                to_folder = os.path.expandvars(command['to'])
                print("    ---> Copying folder '%s' to '%s'"
                      % (from_folder, to_folder))
                shutil.copytree(from_folder, to_folder)
            elif kind == 'append':
                from_file = __expand(command['file'])
                to_file = os.path.expandvars(command['to'])
                print("    ---> Appending package file '%s' to '%s'"
                      % (from_file, to_file))
                with open(to_file, 'a') as to:
                    with open(from_file, 'r') as in_file:
                        to.write(in_file.read())
            elif kind == 'append text':
                to_file = os.path.expandvars(command['to'])
                print("    ---> Appending text to '%s'"
                      % (to_file))
                with open(to_file, 'a') as to:
                    to.write(command['text'])
                    to.write('\n')

        return True
    except Exception as e:
        print("Couldn't install '%s': '%s'!" % (package, e), file=sys.stderr)
        print(e)
        return False
    finally:
        os.chdir(script_directory)

        if prefetch_dir:
            shutil.rmtree(prefetch_dir, True)


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

    success = install_package(package)
    if not success:
        print(" !! Failed to install '%s'" % package)
        PACKAGE_STATUS[package] = 'failed'
        break  # Explicitly break the loop and write the statuses.

    print("Installed package '%s'." % package)
    PACKAGE_STATUS[package] = 'installed'

with open(os.path.join(os.path.expanduser('~'),
                           '.dotfiles'), 'w') as status:
        json.dump(PACKAGE_STATUS, status,
                  indent=2, sort_keys=True)
