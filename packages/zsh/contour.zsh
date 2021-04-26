if [[ $TERMINAL_NAME != "contour" ]]
then
  return
fi

# Load the integration script from the currently installed Contour executable.
eval "$(contour generate integration shell zsh to -)";
