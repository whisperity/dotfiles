__lastInLbuffer() {
  local array=("${(@s/ /)LBUFFER}")
  echo "${array[-1]}"
}

__lbufferWithoutLast() {
  local array=("${(@s/ /)LBUFFER}")
  unset "array[-1]"
  echo "${array[@]}"
}

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

# fgst - pick files from `git status -s`
__fgst() {
  # "Nothing to see here, move along"
  is_in_git_repo || return 1

  setopt localoptions pipefail 2> /dev/null
  git status -s | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -1 --query="$(__lastInLbuffer)" | awk '{print $2}'
  local ret=$?
  return "$ret"
}

# Select one file from git status.
fzf-git-files-widget() {
  local selected
  selected=$(__fgst)
  # The user successfully selected one element so update the LBUFFER.
  if [ $? -eq 0 ]; then
    LBUFFER="$(__lbufferWithoutLast)$selected"
  fi
  local ret=$?
  zle reset-prompt
  return $ret
}
zle     -N   fzf-git-files-widget
bindkey '^G' fzf-git-files-widget
