" Install the themes we use.

" Used for Light theme.
Plug 'arzg/vim-colors-xcode'

" Used for Dark theme.
Plug 'dracula/vim', {'as': 'dracula'}


" ----------------------------------------------------------------------------
" And some more.
" Note: These themes are *reasonably* okay, but not the best.
"       Keeping them here for an eventual retry.

" Plug 'whatyouhide/vim-gotham'
" Plug 'cocopon/iceberg.vim'
" Plug 'nanotech/jellybeans.vim'

" Superseded by 'arzg/vim-colors-xcode'...
" Plug 'rakr/vim-one'

" The good old default dark theme.
" Plug 'tomasr/molokai'
" augroup MolokaiFix
"     " Fixing the Conceal colours manually kind of patches it, but it's not a
"     " real good fix...
"     autocmd!
"     autocmd ColorScheme molokai hi! link Conceal Comment
" augroup END

" Plug 'bluz71/vim-nightfly-guicolors'
" augroup NightflyFix
"     autocmd!
"     autocmd ColorScheme nightfly hi! link Conceal Comment
" augroup END

" These have UNREADABLE comments in Dark mode.
" Plug 'TheNiteCoder/mountaineer.vim'
" Plug 'pineapplegiant/spaceduck'
