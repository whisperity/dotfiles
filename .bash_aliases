# Some more ls aliases.
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lh='ls -lh'

alias ..='cd ..'

# Find the argument in all files in the current directory.
# Usage: fse "my_string_to_find".
alias fse='grep -RnwIi "." -e'

# Kill all Python interpreters running under the current shell.
alias killpython="ps -opid,cmd | tail -n +2 | grep python | awk '{print \$1 }' | xargs kill -2"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Add the current working directory to PATH.
alias wd2path='export PATH="$(pwd):$PATH"'
