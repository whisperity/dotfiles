if type "direnv" > /dev/null;
then
  eval "$(direnv hook bash)"
else
  echo "bash.d: 'direnv' binary is not installed - hook cannot execute!" >&2
fi
