if [[ ! $TERM =~ "contour*" ]]
then
  return
fi

# echo "Generating Contour integration..." >&2

local TEMPFILE=$(mktemp --suffix=".zsh")
chmod +x ${TEMPFILE}

local CONTOUR_WHERE="$(which contour)"
local CAT_WHERE="$(which cat)"
local RM_WHERE="$(which rm)"
local OLD_PATH="${PATH}"
unset PATH

# Load the integration script from the currently installed Contour executable.
${CONTOUR_WHERE} generate integration shell zsh to "${TEMPFILE}"
# ${CAT_WHERE} ${TEMPFILE}
# eval $(${CAT_WHERE} ${TEMPFILE})
source ${TEMPFILE}
${RM_WHERE} ${TEMPFILE}

export PATH="${OLD_PATH}"
