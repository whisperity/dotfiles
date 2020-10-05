#!/bin/sh

if [ -z "$VIM_ALIAS_EXPANDED" ]
then
    export VIM_THEME=dark

    alias darkvim="VIM_THEME=dark $(command -v vim) "
    alias lightvim="VIM_THEME=light $(command -v vim) "

    alias vim="darkvim"

    export VIM_ALIAS_EXPANDED=1
fi

