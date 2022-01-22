" Focused writing (hide everything)
Plug 'junegunn/goyo.vim'

" FIXME: :ContextToggle when entering and leaving Goyo, and
" call :Goyo! (leave Goyo forcibly) before Startify saves the session.

nnoremap <silent> <C-c><C-g> :Goyo<CR>



" Focused writing (shadow outside context)
Plug 'junegunn/limelight.vim'

" Shadow multiplier (default 0.5)
let g:limelight_default_coefficient = 0.75

" Number of preceding/following paragraphs to include (default: 0)
let g:limelight_paragrap_scan = 1

nnoremap <silent> <C-c><C-l> :Limelight!!<CR>
