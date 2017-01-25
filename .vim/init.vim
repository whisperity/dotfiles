" Pathogen
if has('nvim')
  " My nvim is compiled without python2 support atm.
  let g:pathogen_disabled = ['YouCompleteMe']
endif

execute pathogen#infect()

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

" Performance for Raspberry or other low end systems.
" Also turn line numbering off!
" set nocursorcolumn
" set nocursorline
" set norelativenumber
" syntax sync minlines=256


" General
set nocompatible
set history=7000
set backspace=indent,eol,start

" Theme
set background=dark
colorscheme molokai

" Syntax highlighting
syntax on
filetype plugin indent on

" Numbering
set number
"set relativenumber

set hidden

" Set to auto read when a file is changed from the outside
set autoread

" Completions
set wildmenu
set showcmd

" Show line and column
set ruler
" Show the 80 column limit
set colorcolumn=80

" highlighting search
set hlsearch

" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase

set autoindent

" Instead of failing a command because of unsaved changes, instead raise a
" dialogue asking if you wish to save changed files.
set confirm

" Enable use of the mouse for all modes
set mouse=a

" Set the command window height to 2 lines, to avoid many cases of having
" to "press <Enter> to continue"
" set cmdheight=2

" tabs to spaces
set expandtab

set shiftwidth=4
set tabstop=2

set smarttab

" Matching braces
set showmatch
" Matching angle brackets for metaprograms
set matchpairs+=<:>

" For airline
set laststatus=2

" Ignore compiled files
set wildignore=*.o,*~,*.pyc

" No annoying sound on errors
"set noerrorbells
"set novisualbell

" Turn backup off, since most stuff is in SVN, git et.c anyway...
"set nobackup
"set nowb
"set noswapfile

" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif
" Remember info about open buffers on close
set viminfo^=%

" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

"map <up> <nop>
"map <down> <nop>
"map <left> <nop>
"map <right> <nop>

noremap  <buffer> <silent> k gk
noremap  <buffer> <silent> j gj
noremap  <buffer> <silent> gk k
noremap  <buffer> <silent> gj j

" Buffer switch
nnoremap <F3> :bnext <CR>
nnoremap <F2> :bprevious <CR>
nnoremap <F4> :buffers<CR>:buffer<Space>

command Bc bp|bd#
command C let @/=""

" Quickly turn paste mode on or off
command Pon set paste
command Poff set nopaste

" Folding control for markdown
nmap <C-S-o> :foldopen <CR>
nmap <C-S-p> :foldclose <CR>
