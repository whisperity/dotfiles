if [[ $TERMINAL_NAME != "contour" ]]
then
  return
fi

# Returns a temporary file where Contour's capturing should take place.
# Contour does not have a "capture whichever shells" like 'tmux capture-pane',
# only the current terminal can be captured.
# In addition, the result of the capture, when put to the STDOUT, breaks through
# ZLE, so a file should be used...
__getTempfileForContour() {
  local tmpdir="--tmpdir"
  local filepattern="contour.$EUID.XXXX"

  if [[ ! -z "$XDG_RUNTIME_DIR" ]]
  then
    local tmpdir="--tmpdir=$XDG_RUNTIME_DIR"
    local filepattern="contour.XXXX"
  fi

  local tempfile=$(mktemp ${tmpdir} ${filepattern})
  echo ${tempfile}
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
  echo "${array[@]}# "
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

# Print an element selected by fzf from the list of the elements in the
# terminal history. Fzf is fed with the last word on the LBUFFER.
__fselcontourhist() {
  setopt localoptions pipefail 2> /dev/null
  local filter_cmd="$1"
  local tempfile=$(__getTempfileForContour)

  contour capture logical lines 250 timeout 15 output "${tempfile}" >&2
  cat "${tempfile}" | eval "${filter_cmd}" | sort | uniq \
    | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" \
      $(__fzfcmd) --tac --query="$(__lastInLbuffer)"
  local ret=$?
  rm ${tempfile}
  return "$ret"
}

# Select an element from Contour's buffer history, LBUFFER update is implemented here.
__fzf-contour-hist-base() {
  local selected
  local filter_cmd="$1"
  selected=$(__fselcontourhist ${filter_cmd})
  # The user successfully selected one element so update the LBUFFER.
  if [ $? -eq 0 ]; then
    LBUFFER="$(__lbufferWithoutLast)$selected"
  fi
  local ret=$?
  zle reset-prompt
  return $ret
}

# Select one element from Contour history, elements are separated by spaces.
# This is really useful e.g. to get file paths from the history.
fzf-contour-hist-widget() {
  local filter_cmd='tr "[:space:]" "\n"'
  __fzf-contour-hist-base ${filter_cmd}
  return $?
}
zle     -N   fzf-contour-hist-widget
bindkey '^F' fzf-contour-hist-widget

# Select one element from Contour history, elements are separated by spaces and any punctuation.
# This is useful to get vim like Ctrl-P/Ctrl-N word completion.
fzf-contour-hist-words-widget() {
  local filter_cmd='tr "[:space:]" "\n" | tr "[:punct:]" "\n"'
  __fzf-contour-hist-base ${filter_cmd}
  return $?
}
zle     -N   fzf-contour-hist-words-widget
bindkey '^P' fzf-contour-hist-words-widget

# Select one line from Contour history.
fzf-contour-hist-lines-widget() {
  local filter_cmd='tr "\n" "\n"'
  __fzf-contour-hist-base ${filter_cmd}
  return $?
}
zle     -N   fzf-contour-hist-lines-widget
bindkey '^L' fzf-contour-hist-lines-widget
