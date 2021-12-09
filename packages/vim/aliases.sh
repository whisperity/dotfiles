#!/bin/sh

if [[ "$(command -v vim)" != *"darkvim"* && "$(command -v vim)" != *"lightvim"* ]]
then
    export VIM_THEME=dark

    alias darkvim="VIM_THEME=dark $(command -v vim) "
    alias lightvim="VIM_THEME=light $(command -v vim) "

    alias vim="darkvim"
fi
