if type "direnv" > /dev/null;
then
  eval "$(direnv hook zsh)"
else
  echo "zsh.d: 'direnv' binary is not installed - hook cannot execute!" >&2
fi
