#!/bin/bash
# Create a temporary HOME directory and run a shell there to test Dotfiles
# without having to mess up the user's real home.

TEMPHOME=$(mktemp -d)

pushd ${TEMPHOME}
touch .is_dotfiles_temporary_home \
    .sudo_as_admin_successful       # Don't show the Ubuntu default message...
popd

clear
HOME="${TEMPHOME}" bash

# Cleanup.
rm -rf "${TEMPHOME}"
