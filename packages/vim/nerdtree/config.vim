" NERDTree
" Autostart :
" autocmd vimenter * NERDTree

" Key to toggle Nerd Tree
map <silent> <C-n> :NERDTreeToggle<CR>

" Highlight the current file in the NERDTree window.
let g:nerdtree_sync_cursorline = 1

" Show Git status in NERDTree using the default configuration.
let g:NERDTreeGitStatusUseNerdFonts = 1
