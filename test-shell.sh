#!/bin/bash
# Create a temporary HOME directory and run a shell there to test Dotfiles
# without having to mess up the user's real home.

clear

TEMPHOME=$(mktemp -d)
CUR_DIR=$(pwd)

cd ${TEMPHOME}
touch .is_dotfiles_temporary_home \
    .sudo_as_admin_successful

cd ${CUR_DIR}

HOME="${TEMPHOME}" bash -l

rm -rf "${TEMPHOME}"

