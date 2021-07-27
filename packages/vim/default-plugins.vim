" Install some Vim plugins that are mostly always needed.
Plug 'jlanzarotta/bufexplorer'
Plug 'bogado/file-line'
Plug 'danro/rename.vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'machakann/vim-highlightedyank'
Plug 'farmergreg/vim-lastplace'

Plug 'xolox/vim-misc'    " Needed by xolox/vim-reload.
Plug 'xolox/vim-reload'



" ToggleCursor.
Plug 'jszakmeister/vim-togglecursor'
if !has("nvim")
    " Do whatever is needed to detect your terminal.  Many times, this is
    " a simple check of the $TERM or $TERM_PROGRAM environment variables.
    if $TERMINAL_NAME == "contour"
        " Set the kind of escape sequences to use.  Most use xterm-style
        " escaping, there are a few that use the iterm (CursorShape) style
        " sequences.  The two acceptable values to use here are: 'xterm'
        " and 'iterm'.
        let g:togglecursor_force = "xterm"
    elseif !empty("$KONSOLE_DBUS_SERVICE")
        " Konsole is stupid, and will mess up profiles from the escape sequences
        " emitted by the plugin.

        " Make-belive that the plugin has already loaded.
        let g:loaded_togglecursor = 2
    endif

    " Use I-Beam in default mode.
    let g:togglecursor_default = "line"

    " Use blinking line for insertion.
    let g:togglecursor_insert = "blinking_line"

    " Revert back to I-Beam cursor in the terminal after leave.
    let g:togglecursor_leave = "blinking_line"
else
    " ToggleCursor doesn't work for NeoVim, so we need to configure nvim
    " normally.
    let g:togglecursor_disable_neovim = 1
    set guicursor=v-c-sm:block,n-ci-ve:ver25,o:hor20,i:ver25-blinkon500,r:hor20-blinkon500

    " At exit, restore the blinking I-Beam.
    autocmd VimLeave * set guicursor=a:ver25-blinkon500
endif
