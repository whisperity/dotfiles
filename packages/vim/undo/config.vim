" UndoTREE
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }

nmap <silent> <C-c><C-u> :UndotreeToggle<cr>


" Style 2
" +----------+------------------------+
" |          |                        |
" |          |                        |
" | undotree |                        |
" |          |                        |
" |          |                        |
" +----------+------------------------+
" |                                   |
" |   diff                            |
" |                                   |
" +-----------------------------------+
let g:undotree_WindowLayout = 2

" Using 'd' instead of 'days' to save some space.
let g:undotree_ShortIndicators = 1

" Show unified diff.
let g:undotree_DiffCommand = "diff -au"

" Undodir (full undo path instead of % separations)
Plug 'pixelastic/vim-undodir-tree'

" Do not lose undo history.
" Unfortunately only works for Vim >= 7.3.
if has("persistent_undo")
    let undoDirPath = expand($HOME . "/.vim/undo/")
    silent execute '!mkdir -p ' . undoDirPath
    let &undodir = undoDirPath

    set undofile
endif
