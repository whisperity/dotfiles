" Most of the initialisation is common.
let vimRootPath = expand($HOME . "/.vim")
exec printf("source %s/%s.vim", vimRootPath, "settings")

" Load and set up the appropriate theme the user selected.
if $VIM_THEME == "light"
    exec printf("source %s/%s.vim", vimRootPath, "light")
elseif $VIM_THEME == "dark"
    exec printf("source %s/%s.vim", vimRootPath, "dark")
else
    echom "Using dark theme as fallback, no 'VIM_THEME' set"
    exec printf("source %s/%s.vim", vimRootPath, "dark")
endif
