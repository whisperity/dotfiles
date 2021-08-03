" Install some Vim plugins that are mostly always needed.
Plug 'jlanzarotta/bufexplorer'
Plug 'bogado/file-line'
Plug 'danro/rename.vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'machakann/vim-highlightedyank'
Plug 'farmergreg/vim-lastplace'

Plug 'xolox/vim-misc'    " Needed by xolox/vim-reload.
Plug 'xolox/vim-reload'



" Startscreen
Plug 'mhinz/vim-startify'
let g:startify_list_order = [
      \ ['   My most recently used files in the current directory:'],
      \ 'dir',
      \ ['   My most recently used files:'],
      \ 'files',
      \ ['   These are my sessions:'],
      \ 'sessions',
      \ ['   These are my bookmarks:'],
      \ 'bookmarks',
      \ ]
let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'bundle/.*/doc',
      \ ]
let g:startify_change_to_dir = 0
let g:startify_change_to_vcs_root = 1
let g:startify_update_oldfiles = 1



" EditorConfig.
Plug 'editorconfig/editorconfig-vim'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']



" ChooseWin.
Plug 't9md/vim-choosewin'

" Invoke with '-'.
nmap - <Plug>(choosewin)

" Show the letters on the overlay.
let g:choosewin_overlay_enable = 1
let g:choosewin_overlay_shade = 1


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
