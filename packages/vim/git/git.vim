" Fu-Git-ive
Plug 'tpope/vim-fugitive'

nmap <silent> <LocalLeader>gg :Git<CR>
nmap <silent> <LocalLeader>gb :Git blame<CR>



" GitGutter
Plug 'airblade/vim-gitgutter'



" On-demand Git Blamer
Plug 'rhysd/git-messenger.vim'

" Automatic Git Blamer
" Plug 'APZelos/blamer.nvim'
"
" let g:blamer_enabled = 1
" let g:blamer_show_in_visual_modes = 1
" let g:blamer_show_in_insert_modes = 0
" let g:blamer_prefix = '    G> '
" let g:blamer_template = '<author> (<committer-time>, <commit-short>) - <summary>'
" let g:blamer_date_format = '%Y. %b. %d. %H:%M'
" let g:blamer_relative_time = 0
"
" nmap <silent> <LocalLeader>gm :BlamerToggle<CR>



" Merge conflict handling.
Plug 'rhysd/conflict-marker.vim'
