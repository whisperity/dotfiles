if [[ $TERMINAL_NAME != "contour" ]]
then
  return
fi

local CONTOUR_WHERE="$(which contour)"
local OLD_PATH="${PATH}"
unset PATH
# Load the integration script from the currently installed Contour executable.
eval "$(${CONTOUR_WHERE} generate integration shell zsh to -)";
export PATH="${OLD_PATH}"
