#!/bin/sh

if [[ "$(command -v vim)" != *"darkvim"* && "$(command -v vim)" != *"lightvim"* ]]
then
    if [[ -z "${VIM_THEME}" || ("${VIM_THEME}" != "dark" && "${VIM_THEME}" != "light") ]]
    then
        echo "env/vim: VIM_THEME set to unrecognised \"${VIM_THEME}\", defaulting to \"dark\" instead." >&2
        export VIM_THEME=dark
    fi

    alias darkvim="VIM_THEME=dark $(command -v nvim) "
    alias lightvim="VIM_THEME=light $(command -v nvim) "

    if [[ "${VIM_THEME}" == "dark" ]]
    then
        alias vim="darkvim"
    elif [[ "${VIM_THEME}" == "light" ]]
    then
        alias vim="lightvim"
    fi
fi
