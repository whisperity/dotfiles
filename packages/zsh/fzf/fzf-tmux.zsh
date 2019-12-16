# Print the content of all panes in one tmux session.
# The content is filtered through the given parameter: $1.
__allpanes() {
  local filter_cmd="$1"
  for w in $(tmux list-windows -F '#{window_index}') ;do
    for p in $(tmux list-panes -t "$w" -F '#{pane_index}') ;do
      tmux capture-pane -pt "$w.$p" -S -200 -J | eval ${filter_cmd}
    done
  done
}

# Print the last element (delimited by strings) in the left buffer of ZLE.
# E.g. $ apple banana
#                    ^ cursor position
#   gives "banana"
__lastInLbuffer() {
  local array=("${(@s/ /)LBUFFER}")
  echo "${array[-1]}"
}

# Print all elements except the last (delimited by strings) in the left buffer
# of ZLE.
# E.g. $ apple banana
#                    ^ cursor position
#   gives "apple "
__lbufferWithoutLast() {
  local array=("${(@s/ /)LBUFFER}")
  unset "array[-1]"
  echo "${array[@]}"
}

# To test the auxiliary LBUFFER functions:
# __test() {
#   LBUFFER="${LBUFFER}$(__lbufferWithoutLast)"
#   local ret=$?
#   zle reset-prompt
#   return $ret
# }
# zle     -N   __test
# bindkey '^E' __test

# Print an element selected by fzf from the list of the elements in the tmux
# panes history. Fzf is fed with the last word on the LBUFFER.
__fseltmuxhist() {
  setopt localoptions pipefail 2> /dev/null
  local filter_cmd="$1"
  __allpanes ${filter_cmd} | sort | uniq | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) --tac --query="$(__lastInLbuffer)"
  local ret=$?
  return "$ret"
}

# Select an element from tmux history, LBUFFER update is implemented here.
__fzf-tmux-hist-base() {
  local selected
  local filter_cmd="$1"
  selected=$(__fseltmuxhist ${filter_cmd})
  # The user successfully selected one element so update the LBUFFER.
  if [ $? -eq 0 ]; then
    LBUFFER="$(__lbufferWithoutLast)$selected"
  fi
  local ret=$?
  zle reset-prompt
  return $ret
}

# Select one element from tmux history, elements are separated by spaces.
# This is really useful e.g. to get file paths from the history.
fzf-tmux-hist-widget() {
  local filter_cmd='tr "[:space:]" "\n"'
  __fzf-tmux-hist-base ${filter_cmd}
  return $?
}
zle     -N   fzf-tmux-hist-widget
bindkey '^F' fzf-tmux-hist-widget

# Select one element from tmux history, elements are separated by spaces and any punctuation.
# This is useful to get vim like Ctrl-P/Ctrl-N word completion.
fzf-tmux-hist-words-widget() {
  local filter_cmd='tr "[:space:]" "\n" | tr "[:punct:]" "\n"'
  __fzf-tmux-hist-base ${filter_cmd}
  return $?
}
zle     -N   fzf-tmux-hist-words-widget
bindkey '^P' fzf-tmux-hist-words-widget
