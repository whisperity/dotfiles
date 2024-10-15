#!/bin/zsh

if [[ ! $TERM =~ "contour*" ]]
then
  return
fi

# echo "Generating Contour integration..." >&2

local CONTOUR_WHERE="$(whence -p contour)"
if [[ -z "${CONTOUR_WHERE}" ]];
then
  echo "zsh.d: 'contour' not installed - refusing to run integration script!" >&2
  return
fi

local CAT_WHERE="$(whence -p cat)"
local RM_WHERE="$(whence -p rm)"
if [[ -z "${CAT_WHERE}" || -z "${RM_WHERE}" ]];
then
  echo "zsh.d: contour: 'cat' or 'rm' does not exist. Is this system broken?" >&2
  return
fi

local TEMPFILE=$(mktemp)
mv ${TEMPFILE} ${TEMPFILE}.zsh
local TEMPFILE="${TEMPFILE}.zsh"
chmod +x ${TEMPFILE}

local OLD_PATH="${PATH}"
unset PATH

# Load the integration script from the currently installed Contour executable.
${CONTOUR_WHERE} generate integration shell zsh to "${TEMPFILE}"
# ${CAT_WHERE} ${TEMPFILE}
# eval $(${CAT_WHERE} ${TEMPFILE})
source ${TEMPFILE}
${RM_WHERE} ${TEMPFILE}

export PATH="${OLD_PATH}"
