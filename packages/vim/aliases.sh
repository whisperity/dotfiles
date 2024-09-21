#!/bin/sh

if [[ "$(command -v vim)" != *"darkvim"* && "$(command -v vim)" != *"lightvim"* ]]
then
    if [[ -z "${VIM_THEME}" || ("${VIM_THEME}" != "dark" && "${VIM_THEME}" != "light") ]]
    then
        echo "env/vim: VIM_THEME set to unrecognised \"${VIM_THEME}\", defaulting to \"dark\" instead." >&2
        export VIM_THEME=dark
    fi

    if [[ "$(command -v nvim)" == *"nvim"* ]]
    then
        alias darkvim="VIM_THEME=dark $(command -v nvim) "
        alias lightvim="VIM_THEME=light $(command -v nvim) "

        alias vim="darkvim"

        echo "vim: Using 'nvim' as 'vim', with VIM_THEME='dark' by default." >&2

        if [[ -z "$GIT_EDITOR" ]]
        then
            export GIT_EDITOR="$(which nvim)"
            echo "vim: Using 'nvim' as GIT_EDITOR." >&2
        fi
    elif [[ "$(command -v vim)" == *"vim"* ]]
    then
        alias darkvim="VIM_THEME=dark $(command -v vim) "
        alias lightvim="VIM_THEME=light $(command -v vim) "

        alias vim="darkvim"

        echo "vim: Using 'vim', with VIM_THEME='dark' by default." >&2

        if [[ -z "$GIT_EDITOR" ]]
        then
            export GIT_EDITOR="$(which vim)"
            echo "vim: Using 'vim' as GIT_EDITOR." >&2
        fi
    else
        echo "vim: Neither 'vim' nor 'nvim' installed!" >&2
    fi
fi
