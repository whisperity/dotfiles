" Pathogen
if has('nvim')
  " My nvim is compiled without python2 support atm.
  let g:pathogen_disabled = ['YouCompleteMe']
endif

" Neovim
if has('nvim')
  tnoremap <Esc> <C-\><C-n>
endif

" Airline
set t_Co=256
let g:airline_powerline_fonts = 1
let g:bufferline_echo = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline_left_sep = ''
let g:airline_right_sep = ''

" Syntastic
let g:syntastic_cpp_check_header = 1
let g:syntastic_cpp_compiler_options = '-std=c++14 -Wall -Wextra'
let g:syntastic_cpp_config_file = '.config'
let g:syntastic_cpp_remove_include_errors = 1
if has('nvim')
  let g:syntastic_cpp_compiler = 'clang++'
else
  " Use YCM for vim.
  let g:syntastic_cpp_compiler = 'clang++'
endif

let g:syntastic_python_checkers=['python', 'pep8']

" YCM
let g:ycm_confirm_extra_conf = 0
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1

" NerdTree
" Autostart :
" autocmd vimenter * NERDTree

" Key to toggle Nerd Tree
map <C-n> :NERDTreeToggle<CR>

" Key to toggle Undo Tree
map <F5> :UndotreeToggle<cr>

" Clang Format
let g:clang_format#code_style = 'llvm'
map <C-f> :ClangFormat <CR>

