if $VIM_THEME == 'light'
    source ~/.vim/light.vim
elseif $VIM_THEME == 'dark'
    source ~/.vim/dark.vim
else
    echom "Using dark theme as fallback, no 'VIM_THEME' set"
    source ~/.vim/dark.vim
endif

" Rest of the initialisation is common.
source ~/.vim/settings.vim
