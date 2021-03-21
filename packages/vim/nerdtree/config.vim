" NERDTree
Plug 'scrooloose/nerdtree'

" Autostart :
" autocmd vimenter * NERDTree

" Key to toggle Nerd Tree
map <silent> <C-n> :NERDTreeToggle<CR>

" Highlight the current file in the NERDTree window.
Plug 'unkiwii/vim-nerdtree-sync'
let g:nerdtree_sync_cursorline = 1

" Show Git status in NERDTree using the default configuration.
Plug 'Xuyuanp/nerdtree-git-plugin'
let g:NERDTreeGitStatusUseNerdFonts = 1

" Show file-type icons to various plugins, but most importantly NERDTree.
Plug 'ryanoasis/vim-devicons'
