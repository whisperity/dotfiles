#!/bin/bash
# SYNOPSIS: Bootstrap Dotfiles in case the user's environment does not have
# mandatory Python packages that make the tool work installed.

function get_script_location() {
    # (via https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself/246128#246128)
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

    echo ${DIR}
}


# Check for already existing environment
if [[ -f "$(get_script_location)/venv/bin/activate" ]]
then
    echo "A virtual environment in which Dotfiles could be run had already" \
         "been created by this script."
    echo "Please execute in your shell:"
    echo "    source \"$(get_script_location)/venv/bin/activate\""
    exit 0
fi


# Check if the Python interpreter has 'distutils' available.
CHECK_DISTUTILS_EXISTS=$(/usr/bin/env python3 -m distutils 2>&1 | grep "ImportError")
if [[ "${CHECK_DISTUTILS_EXISTS}" =~ "cannot import name 'dist'" ]]
then
    echo "Error: Your system does not have 'python3-distutils' installed."
    echo "Without this package, Python packages and environments can't be" \
         "created."
    echo
    echo "On Ubuntu/Debian systems, execute"
    # (If we are already asking the user to sudo, they might just as well
    # install the dependencies we need...)
    echo "    apt-get install --no-install-recommends python3-distutils" \
         "python3-tabulate python3-yaml"
    echo "in superuser mode. On other systems, please find the equivalent of" \
         "this package."
    echo
    echo "(Alternatively, please install the Python interpreter from source" \
         "with this package present, or obtain a binary release.)"

    exit 1
fi


# Check if the Python interpreter has 'tabulate' available.
CHECK_TABULATE_EXISTS=$(echo "test" | /usr/bin/env python3 -m tabulate 2>&1 | grep "No module named tabulate$")
if [[ ! -z "${CHECK_TABULATE_EXISTS}" ]]
then
    echo "Warning: Your system does not have 'python3-tabulate' installed."
    echo
    echo "Will try to fix this..."
else
    echo "TABULATE support seems to be installed."
    HAVE_TABULATE=1
fi

# Check if the Python interpreter has 'yaml' available.
CHECK_YAML_EXISTS=$(/usr/bin/env python3 -m yaml 2>&1 | grep "No module named yaml$")
if [[ ! -z "${CHECK_YAML_EXISTS}" ]]
then
    echo "Warning: Your system does not have 'python3-yaml' installed."
    echo "Without this package, Dotfiles package metadata files can't be read."
    echo
    echo "Will try to fix this..."
else
    echo "YAML support seems to be installed."
    HAVE_YAML=1
fi

if [[ $HAVE_TABULATE -eq 1 && $HAVE_YAML -eq 1 ]]
then
    echo
    echo "Every dependency is satisfied in the current environment."


    if [[ "$1" =~ (-f|--force) ]]
    then
        echo "'-f/--force' was given: considering as if dependencies weren't" \
             "satisfied."
    else
        echo "You may run the script normally!"
        exit 0
    fi
fi


# Obtain get-pip helper script from the Internet.
if [[ ! -f "get-pip.py" ]]
then
    GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
    if [[ ! -z "$(which wget)" ]]
    then
        wget --no-verbose\
             --no-hsts \
             --https-only \
             --output-document=get-pip.py \
             ${GET_PIP_URL}
    elif [[ ! -z "$(which curl)" ]]
    then
        curl --silent --show-error \
             --location \
             --output get-pip.py \
             ${GET_PIP_URL}
    else
        echo "Error: No useful means of just downloading files from the" \
             "internet found."
        echo "Please run in an environment sensible enough at least to" \
             "contain 'wget' or 'curl' in the PATH."
        echo
        echo "On Ubuntu/Debian systems, execute"
        echo "    apt-get install --no-install-recommends wget"
        echo "or"
        echo "    apt-get install --no-install-recommends curl"
        echo "in superuser mode. On other systems, please find the equivalent" \
             "of this package."
        echo
        echo "(Alternatively, you could compile the aforementioned binaries" \
             "from source or obtain a binary release.)"

        exit 1
    fi

    if [[ ! -f "get-pip.py" ]]
    then
        echo "Failed to download a pre-packaged 'pip' for Python."
        exit 1
    fi
fi

# Execute get-pip to extract a precompiled 'pip' to be useful.
INSTALL_PREFIX="$(echo $(get_script_location)/tmp.*)"
if [[ ! -d ${INSTALL_PREFIX} ]]
then
    INSTALL_PREFIX="$(mktemp --suffix=venv -d -p $(get_script_location))"
fi

export OLD_HOME="${HOME}"
export HOME="${INSTALL_PREFIX}"
echo "Running under temporary 'HOME' overridden to ${HOME}..."

echo
echo "Installing a pre-packaged version of 'pip'..."
python3 "./get-pip.py" \
    --prefix="${INSTALL_PREFIX}" || { echo "Failed to extract 'pip'!"; exit 1; }

echo
echo "Using pre-packaged pip to obtain 'virtualenv' for virtualenv creation..."

export PYTHONPATH="$(echo ${INSTALL_PREFIX}/lib/python*/site-packages)"
python3 \
    -m pip \
    install \
    --prefix="${INSTALL_PREFIX}" \
    virtualenv || { echo "Failed to download 'virtualenv'!"; exit 1; }

echo
echo "Creating a proper Python virtual environment..."
"${INSTALL_PREFIX}/bin/virtualenv" --clear "$(get_script_location)/venv" \
    --prompt="[[Dotfiles]] " || { echo "Failed to create virtualenv!"; exit 1; }

unset PYTHONPATH

echo
echo "Installing PyPI packages required..."
source "$(get_script_location)/venv/bin/activate"
pip install tabulate || { echo "Failed to install 'tabulate'!"; exit 1; }
pip install pyyaml || { echo "Failed to install 'pyyaml'!"; exit 1; }
deactivate

export HOME="${OLD_HOME}"
unset OLD_HOME

echo
echo "Cleaning up..."
rm -r "${INSTALL_PREFIX}"
rm "./get-pip.py"

echo
echo
echo "------------------------------------------------------------------------"
echo "A Python virtual environment with the necessary dependencies have been" \
     "created."
echo "Please execute Dotfiles with the following:"
echo "    source \"$(get_script_location)/venv/bin/activate\""
echo "After sourcing the environment, you may execute the script normally."
exit 0
