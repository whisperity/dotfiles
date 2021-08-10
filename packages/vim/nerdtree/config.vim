if mapcheck('<C-n>', 'n') == ""
    " Only install NERDTree if a previous plugin (Coc.nvim) didn't "hijack"
    " the C-n keybind already.

    " NERDTree
    Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }

    " Autostart :
    " autocmd vimenter * NERDTree

    " Key to toggle NerdTREE
    nmap <silent> <C-n> :NERDTreeToggle<CR>

    " Highlight the current file in the NERDTree window.
    Plug 'unkiwii/vim-nerdtree-sync', { 'on': 'NERDTreeToggle' }
    let g:nerdtree_sync_cursorline = 1

    " Show Git status in NERDTree using the default configuration.
    Plug 'Xuyuanp/nerdtree-git-plugin', { 'on': 'NERDTreeToggle' }
    let g:NERDTreeGitStatusUseNerdFonts = 1

    " Show file-type icons to various plugins, but most importantly NERDTree.
    Plug 'ryanoasis/vim-devicons'
endif
