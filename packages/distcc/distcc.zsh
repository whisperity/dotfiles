#!/bin/zsh
# Forward script to Bash-based distcc.sh

# Prepares running the build remotely. This is the entry point of the script.
distcc_build() {
    bash -c "source ~/.bash.d/distcc.sh; distcc_build $@"
}

