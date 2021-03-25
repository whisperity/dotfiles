" Most of the initialisation is common.
source ~/.vim/settings.vim

" Load and set up the appropriate theme the user selected.
if $VIM_THEME == 'light'
    source ~/.vim/light.vim
else
    source ~/.vim/dark.vim
endif
