# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=-1 #1000
HISTFILESIZE=-1 #2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color|screen) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi


# Put together a nice prompt, first the basics.
prompt_basic()
{
    local RESET='\[\e[0m\]'
    local Red='\[\e[1;31m\]'
    local Green='\[\e[1;32m\]'
    local Yellow='\[\e[1;33m\]'
    local LBlue='\[\e[1;34m\]'
    local White='\[\e[1;37m\]'

    if [ ${EUID} -eq 0 ];
    then
        PROMPT_USERNAME="${Red}\u${RESET}"
        PROMPT_HOSTNAME="${Red}\h${RESET}"
        PROMPT_FOLDER="${Yellow}\w${RESET}"
        PROMPT_CHAR="${Red}\\\$${RESET}"
    else
        PROMPT_USERNAME="${Green}\u${RESET}"
        PROMPT_HOSTNAME="${Yellow}\h${RESET}"
        PROMPT_FOLDER="${LBlue}\w${RESET}"
        PROMPT_CHAR="${White}\\\$${RESET}"
    fi

    echo -en "${PROMPT_USERNAME}@${PROMPT_HOSTNAME}:${PROMPT_FOLDER} ${PROMPT_CHAR} "
}

prompt_time()
{
    local RESET='\[\e[0m\]'
    local White='\[\e[1;37m\]'

    echo -en "${White}\A${RESET}"
}

# Helper function to nicely format the number of jobs running in the shell.
prompt_jobs()
{
  local running=$(jobs -rp | wc -l)
  local stopped=$(jobs -sp | wc -l)

  local RESET='\e[0m'
  local Magenta='\e[1;35m'
  local Cyan='\e[1;36m'

  ((running || stopped)) && echo -n " "
  ((running)) && echo -en "${Cyan}R:${running}${RESET}"
  ((running && stopped)) && echo -en "/"
  ((stopped)) && echo -en "${Magenta}S:${stopped}${RESET}"
}


prompt_chroot()
{
    local RESET='\e[0m'
    local LBlue='\e[1;34m'

    if [ ! -z ${debian_chroot} ];
    then
      echo -en " ${LBlue}${debian_chroot}${RESET} "
    fi

}

prompt_exitcode()
{
    local RESET='\e[0m'
    local Red='\e[1;31m'
    local Green='\e[0;32m'
    local DYellow='\e[0;33m'
    local DBlue='\e[0;34m'
    local Purple='\e[0;35m'

    # Exit code can be a 3-character long number at max (0..256 or -127..128).
    # Pad this number and justify to the right so it looks good.
    local Length=$(echo -n "$1" | wc -c)
    local Padding=$((3 - ${Length}))

    if [ "$1" != 0 ];
    then
        echo -en "$(printf "%${Padding}s")${Red}$1${RESET}"
    else
        echo -en "$(printf "%${Padding}s")${DYellow}$1${RESET}"
    fi
}


if [ "$color_prompt" = yes ]; then
    # Saving out exitcode first to ensure it is picked up properly.
    PROMPT_EXITCODE='$(prompt_exitcode $?)'
    PROMPT_JOBS='`if [ -n "$(jobs -p)" ]; then echo "$(prompt_jobs)"; fi`'

    PS1="${PROMPT_EXITCODE} $(prompt_time)$(prompt_chroot)${PROMPT_JOBS} $(prompt_basic)"
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export EDITOR="vim"
export VISUAL="$EDITOR"

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

