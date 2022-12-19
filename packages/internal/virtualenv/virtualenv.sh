#!/bin/bash
# SYNOPSIS: Do everything that is necessary to create a Python virtualenv in a
# specific directory.

function install_with_virtualenv() {
  VIRTUALENV=$(which virtualenv)
  if [[ ! -z "$VIRTUALENV" ]]
  then
    # The 'virtualenv' command was found, use it to create the virtualenv.
    echo "virtualenv: Creating with PyPI tooling at \"${VIRTUALENV}\"" >&2

    virtualenv "$@"
    VIRTUALENV_RETCODE=$?
    return $?
  else
    echo "virtualenv: 'virtualenv' not found in PATH..." >&2
    return 86
  fi
}

# Check if the global Python interpreter has 'venv' available.
# This likely came from some "official" source.
CHECK_VENV_EXISTS=$(/usr/bin/env python3 -m venv 2>&1 | grep "No module named venv$")
if [[ -z "${CHECK_VENV_EXISTS}" ]]
then
    # 'venv' is already installed, create a virtualenv with that.
    echo "virtualenv: Creating with official Python3." >&2
    /usr/bin/env python3 -m venv "$@"
    VENV_RETCODE=$?
    exit $VENV_RETCODE
else
    echo "virtualenv: Official 'python3-venv' not installed, trying library..." >&2
fi


WHICH_PIP=$(which pip)
if [[ -z $WHICH_PIP ]]
then
  echo "ERROR: No 'pip' found available." >&2
  echo "Have you run 'bootstrap.sh' for the Dotfiles-Framework project?" >&2
  exit 1
fi

pip install virtualenv

# We were likely in a virtualenv or a good enough user context. Try installing
# this way first, hoping it would succeed.
install_with_virtualenv "$@"
VIRTUALENV_RETCODE=$?

if [[ $VIRTUALENV_RETCODE -eq 86 ]]
then
  # The install failed because 'virtualenv' is not found. Likely this is
  # because the 'pip' command was the *global* pip, installing under ~/.local
  # by default.
  PATH_OLD="${PATH}"
  export PATH="$HOME/.local/bin:${PATH}"
  install_with_virtualenv "$@"
  VIRTUALENV_RETCODE=$?
  export PATH="${PATH_OLD}"
fi

if [[ $VIRTUALENV_RETCODE -ne 0 ]]
then
  echo "virtualenv: Install failed after second try." >&1
  exit $VIRTUALENV_RETCODE
fi
