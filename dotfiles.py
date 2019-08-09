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
        return ""

from dotfiles import argument_expander
from dotfiles import package
from dotfiles import temporary
from dotfiles.lazy_dict import LazyDict
from dotfiles.saved_data import get_user_save, UserSave


if __name__ != "__main__":
    # This script is a user-facing entry point.
    raise ImportError("Do not use this as a module!")

# -----------------------------------------------------------------------------
# Define command-line interface.

PARSER = argparse.ArgumentParser(
    prog='dotfiles',
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
                    help="""Installs the specified packages, and its
                            dependencies. This is the default action if at
                            least one package name is specified.""")

ACTION.add_argument('-u', '--uninstall',
                    dest='action',
                    action='store_const',
                    const='REMOVE',
                    default=False,
                    help="""Uninstalls the specified packages, and other
                            packages that depend on them.""")

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

# -----------------------------------------------------------------------------


def _fetch_packages():
    """
    Load the list of available packages from the project to the memory map.
    The packages itself won't be parsed or instantiated, only the name storage
    is loaded.
    """

    def __package_factory(package_name):
        """
        Dispatches the actual creation of the `package.Package` instance for
        the given logical `package_name` to the appropriate factory method.
        """
        if get_user_save().is_installed(package_name):
            # If the package is installed, the data should be created from the
            # archive corresponding for the package's last install state.
            with get_user_save().get_package_archive(package_name) as zipf:
                return package.Package.create_from_archive(package_name, zipf)
        else:
            # If the package is not installed, load data from the repository.
            return package.Package.create(package_name)

    repository_packages = set(package.get_package_names(
            package.Package.package_directory))
    installed_packages = set(get_user_save().installed_packages)
    package_names = repository_packages | installed_packages

    return LazyDict(
        factory=__package_factory,
        initial_keys=package_names)


def _list(p, user_filter=None):
    """
    Performs listing the package details from the `p` package dict.
    """
    if not user_filter:
        # If the user did not filter the packages to list, list everything.
        user_filter = p.keys()

    headers = ["St", "Package", "Description"]
    table = []
    for package_name in sorted(user_filter):
        try:
            instance = p[package_name]
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


def prepend_install_dependencies(p, packages_to_install):
    """
    Check the dependencies of the packages the user wanted to install and
    extend the install list with the unmet dependencies, creating a sensible
    order of package installations.
    """
    installed_packages = list(get_user_save().installed_packages)

    for name in list(packages_to_install):  # Work on copy of original input.
        instance = p[name]
        if instance.is_support:
            print("%s is a support package that is not to be directly "
                  "installed, its life is restricted to helping other "
                  "packages' installation process!" % name, file=sys.stderr)
            sys.exit(1)
        if instance.is_installed:
            print("%s is already installed -- skipping." % name)
            packages_to_install.remove(name)
            continue

        unmet_dependencies = package.get_dependencies(
            p, instance, installed_packages)
        if unmet_dependencies:
            print("%s needs dependencies to be installed: %s"
                  % (name, ', '.join(unmet_dependencies)))
            packages_to_install.extendleft(unmet_dependencies)

    packages_to_install = deque(
        argument_expander.deduplicate_iterable(packages_to_install))
    return packages_to_install


def append_uninstall_dependents(p, packages_to_remove):
    """
    Check the dependencies of packages known to be installed and extend
    the removal list with the dependents of the packages the user intended to
    remove, creating a sensible order of removals.
    """
    installed_packages = list(get_user_save().installed_packages)

    for name in list(packages_to_remove):  # Work on copy of original input.
        instance = p[name]
        if instance.is_support:
            print("%s is a support package that is not to be directly "
                  "removed, its life is restricted to helping other "
                  "packages' installation process!" % name, file=sys.stderr)
            sys.exit(1)
        if not instance.is_installed:
            print("%s is not installed -- nothing to uninstall." % name)
            packages_to_remove.remove(name)
            continue

    # TODO: Perhaps at install save what a package depended on so this does not
    #       need to be manually calculated for each installed package.
    removal_set = set(packages_to_remove)
    for name in get_user_save().installed_packages:
        instance = p[name]
        dependencies_marked_for_removal = set(
            package.get_dependencies(p, instance)).intersection(removal_set)
        if dependencies_marked_for_removal:
            print("%s has dependencies to be uninstalled: %s"
                  % (name, ', '.join(sorted(dependencies_marked_for_removal))))

            removal_set.add(name)
            packages_to_remove.appendleft(name)

    packages_to_remove = deque(
        argument_expander.deduplicate_iterable(packages_to_remove))
    return packages_to_remove


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


# -----------------------------------------------------------------------------
# Handle executing the actual install steps.

def _install(p, package_names):
    """
    Actually perform preparation and installation of the packages specified.
    """
    while package_names:
        print("-------------------=======================--------------------")
        instance = p[package_names.popleft()]

        # Check if any dependency of the package has failed to install.
        for dependency in instance.dependencies:
            try:
                d_instance = p[dependency]
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
            # package even if it does not do any action.)
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

            # Save the package's metadata and the current state of its
            # resource files into the user's backup archive.
            with get_user_save().get_package_archive(instance.name) as zipf:
                package.Package.save_to_archive(instance, zipf)
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
                get_user_save().save_status(instance)


def _uninstall(p, package_names):
    """
    Actually perform removal of the packages specified.
    """
    while package_names:
        print("-------------------=======================--------------------")
        instance = p[package_names.popleft()]
        print("Selecting package '%s'" % instance.name)

        if not instance.has_uninstall_actions:
            print("Nothing to do for uninstall of '%s'." % instance.name)
            continue

        try:
            print("Removing '%s'..." % instance.name)
            instance.execute_uninstall()
        except Exception as e:
            print("Failed to uninstall '%s'!"
                  % instance.name, file=sys.stderr)
            print(e)
            import traceback

            traceback.print_exc()

            instance.set_failed()
            continue

        if not instance.is_installed:
            print("Successfully uninstalled '%s'." % instance.name)
            get_user_save().save_status(instance)


# -----------------------------------------------------------------------------
# Entry point.

def _main():
    args = PARSER.parse_args()

    # Handle the default case if the user did not specify an action.
    if not isinstance(args.action, str):
        if not args.package_names:
            args.action = 'LIST'
        else:
            args.action = 'INSTALL'

    if any(['internal' in name for name in args.package_names]):
        print("'internal' is a support package group that is not to be "
              "directly installed, its life is restricted to helping other "
              "packages' installation process!", file=sys.stderr)
        sys.exit(1)

    # Cleanup for (un)install temporaries.
    @atexit.register
    def _clear_temporary_dir():
        if temporary.has_temporary_dir():
            shutil.rmtree(temporary.temporary_dir(), ignore_errors=True)

    # -------------------------------------------------------------------------
    # Load configuration and user status.
    try:
        get_user_save()
        atexit.register(get_user_save().close)  # Temporary should be cleaned.
    except PermissionError:
        print("ERROR! Couldn't get lock on install information!",
              file=sys.stderr)
        print("Another Dotfiles install running somewhere?", file=sys.stderr)
        print("If not please execute: `rm -f %s` and try again."
              % UserSave.lock_file, file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError:
        print("ERROR: User configuration file is corrupt.", file=sys.stderr)
        print("It is now impossible to recover what packages were installed.",
              file=sys.stderr)
        print("Please remove configuration file with `rm %s` and try again."
              % UserSave.state_file, file=sys.stderr)
        print("Every package will be considered never installed.",
              file=sys.stderr)
        sys.exit(1)

    known_packages = _fetch_packages()

    # -------------------------------------------------------------------------
    # Perform action as requested by user.

    specified_packages = deque(argument_expander.package_glob(
        known_packages.keys(), args.package_names))

    if args.action == 'LIST':
        _list(known_packages, specified_packages)
        sys.exit(0)

    # Die if the user specified a package that does not exist.
    invalid_packages = [p for p in specified_packages
                        if p not in known_packages]
    if invalid_packages:
        print("ERROR: Specified to handle packages that are not available!",
              file=sys.stderr)
        print("  Not found:  %s" % ', '.join(invalid_packages),
              file=sys.stderr)
        sys.exit(1)

    # Prepare the list of package that will be modified.
    packages_to_handle = specified_packages
    if args.action == 'INSTALL':
        packages_to_handle = prepend_install_dependencies(known_packages,
                                                          packages_to_handle)
        if not packages_to_handle:
            print("No packages need to be installed.")
            sys.exit(0)
    elif args.action == 'REMOVE':
        packages_to_handle = append_uninstall_dependents(known_packages,
                                                         packages_to_handle)
        if not packages_to_handle:
            print("No packages need to be removed.")
            sys.exit(0)

    # Check if any package to install/uninstall needs superuser to do so.
    has_checked_superuser = None
    for name in list(packages_to_handle):  # Work on copy, iteration modifies.
        instance = known_packages[name]
        if instance.requires_superuser:
            if has_checked_superuser is None:
                print("Package '%s' requires superuser rights to handle!"
                      % name)
                has_checked_superuser = check_superuser()

            if has_checked_superuser is False:
                print("WARNING: Won't handle '%s' as user presented no "
                      "superuser access!" % name, file=sys.stderr)
                instance.set_failed()

    # Perform the actual modification steps.
    if args.action == 'INSTALL':
        print("Will INSTALL the following packages:\n        %s"
              % ' '.join(sorted(packages_to_handle)))
        _install(known_packages, packages_to_handle)
    elif args.action == 'REMOVE':
        print("Will REMOVE the following packages:\n        %s"
              % ' '.join(sorted(packages_to_handle)))
        _uninstall(known_packages, packages_to_handle)


if __name__ == '__main__':
    _main()
