" Ensure every window has a status line.
set laststatus=2

" Airline
Plug 'vim-airline/vim-airline'

set t_Co=256
let g:airline_powerline_fonts = 1
let g:bufferline_echo = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline_left_sep = ''
let g:airline_right_sep = ''

" Enable the battery plugin for Airline
Plug 'lambdalisue/battery.vim'

let g:airline#extensions#battery#enabled = 1
let g:battery#symbol_charging = '⏼'
let g:battery#symbol_discharging = '⏚'
