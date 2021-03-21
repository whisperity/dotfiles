" UndoTREE
Plug 'mbbill/undotree'

nmap <silent> <C-c><C-u> :UndotreeToggle<cr>

" Undodir (full undo path instead of % separations)
Plug 'pixelastic/vim-undodir-tree'

" Do not lose undo history.
" Unfortunately only works for Vim >= 7.3
if has("persistent_undo")
    let undoDirPath = expand($HOME . "/.vim/undo")
    silent execute '!mkdir -p ' . undoDirPath
    let &undodir = undoDirPath

    set undofile
endif
