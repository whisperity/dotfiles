`.`-files
=========

Synopsis
--------

_dotfiles_ are commonly used for synchronising files related to \*nix shell
environments. This project also helps setting up some other necessary
utilities and system packages.

```bash
./dotfiles.py [package [package...]]
```

Usage
-----

The `dotfiles.py` main script handles installing the environment. Specify the
packages to install.

If no packages are specified, the list and description of packages will be
shown.

:warning: **Warning!** The installers in this tool will unconditionally
overwrite some of the most basic configuration files. This tool is intended to
be used when a new machine is installed or you're given access to a new
environment.

### Uninstalling packages
Currently it is not possible to uninstall anything automatically. This feature
is planned for development.

Compatibility
-------------

This tool was used with Ubuntu 16.04 and 18.04 systems using `x86_64`
architecture. Certain tools install
from the _`apt`_ package manager, thus it should work with Debian. Some tools
are self-contained, downloading pre-built binaries.

Developer annotation
--------------------
Packages are present in the `packages` directory, where an arbitrary hierarchy
can be present.

A package is any directory which contains a (valid) `package.json` file.
Subpackages are translated from filesystem hierarchy to logical hierarchy via
`.`, i.e. `tools/system/package.json` denotes the `tools.system` package.

Package descriptor files are JSONs which contain the directives describing
installation and handling of the package. Any other file is disregarded by the
tool unless explicitly used (e.g. being copied).

### Configuration directives

#### `description` (string)

Contains a free form textual description for the package which is printed in the
"help" when `dotfiles.py` is invoked without any arguments.

#### `superuser` (boolean, default: `False`)


#### `dependencies` (list of other package names)


#### `depend_on_parent` (boolean, default: `True`)

### Action directives
