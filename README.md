`.`-files
=========


Synopsis
--------

**dotfiles** repositories are commonly used for synchronising files related to
\*nix shell environments.
In addition to offering a synchronisation source, this piece of software also
helps set up some more sought utilities and tools.

```bash
./dotfiles.py [package [package...]]
```


Usage
-----

The `dotfiles.py` main script handles installing the environment.
Specify the packages to install.

If no packages are specified, the list and description of packages will be
shown.

:warning: **Warning!** The installers in this tool will unconditionally
overwrite some of the most basic configuration files.
This tool is intended to be used when a new user profile is created, such as
when a new machine is installed.

### Uninstalling packages
Currently it is not possible to uninstall packages automatically.
This feature is planned as future development.


Compatibility
-------------

This tool was used with Ubuntu 16.04 and 18.04 systems using `x86_64`
architecture.
Certain tools install from the ***`apt`*** package manager, thus it should work
with Debian too.
Some tools are self-contained, downloading pre-built binaries.


_Developer_ annotation
----------------------

Packages are present in the `packages` directory, where an arbitrary hierarchy
can be present.

A package is any directory which contains a (valid) `package.json` file.
Subpackages are translated from filesystem hierarchy to logical hierarchy via
`.`, i.e. `tools/system/package.json` denotes the `tools.system` package.

Package descriptor files are JSONs which contain the directives describing
installation and handling of the package.
Any other file is disregarded by the tool unless explicitly used, e.g. being
the source of a copy operation.


### Configuration directives

#### `description` (string)

Contains a free form textual description for the package which is printed in
the "help" when `dotfiles.py` is invoked without any arguments.

#### `dependencies` (list of other package names)

The _logical_ names of packages which must be installed before the installation
of the current package could begin.

#### `depend_on_parent` (boolean, default: `true`)

Whether the package should implicitly depend on the parent (e.g. for
`tools.system`, parent is `tools`), assuming the parent is a valid package.

#### `superuser` (boolean, default: `false`)

Whether installing the package requires _superuser_ privileges.
If `true`, the installer will in advance ask for `sudo`.

#### `support` (boolean, default: `false`)

_Support_ packages are packages which have all the necessary directives to
perform an installation, but are **NOT** meant to do persistent changes to the
user's environment and files.

Support packages can be depended upon, but may not be directly installed by
the user.
A support package's "installed" status will not be saved.


### Action directives

The installation of a package consists of two separate phases.
Before the installation of the first package, a **temporary** `$SESSION_DIR` is
created where temporary resources may be shared between packages.
This directory is deleted at the end of execution of all installs.
The usage of this feature is discouraged unless absolutely necessary.

Action directives are laid out in the package descriptor YAML file as
shown below.
Each phase has a **list** of key-value tuples, which will be executed _in the
order_ they are added.
Each tuple must have an **`action`** argument which defines the type/kind of
the action to run.
The rest of the arguments are specific to the _`action`_ specified.


```yaml
prepare:
    - action: shell
      command: echo "True"
```


#### `prepare` (optional)

First, the package's configuration and external dependencies are obtained.
This is called the _preparation phase_.

At the beginning of this phase, the executing environment switches into a
temporary folder.
In most directives, `$TEMPORARY_DIR` can be used to refer to this directory.


|   Action    | Arguments                    | Semantics                                         | Failure condition                     |
|:-----------:|------------------------------|:--------------------------------------------------|:--------------------------------------|
| `shell`     | `command` (string)           | Execute `command` in a shell.                     | Non-zero return                       |
| `shell all` | `commands` (list of strings) | Execute every command in order.                   | At least one command returns non-zero |
| `shell any` | `commands` (list of strings) | Execute the commands in order until one succeeds. | None of the commands returns zero     |


#### `install`

The installation starts from the `packages/foo/bar/` directory (for package
`foo.bar`).
This phase is the _main_ phase where changes to the user's files should be
done.

In most directives, `$TEMPORARY_DIR` can be used to refer to the _`prepare`_
phase's directory.
`$PACKAGE_DIR` refers to the persistent package directory.

> **TODO:** Directives that can be used in `install` phase.
