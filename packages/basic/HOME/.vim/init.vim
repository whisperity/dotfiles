" Neovim
if has('nvim')
  tnoremap <Esc> <C-\><C-n>
endif

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

" Preserve a changed buffer if a new file is opened rather than forcing a
" write or undo.
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
set cmdheight=2

" tabs to spaces
set expandtab

set shiftwidth=2
set tabstop=2

set smarttab

" Matching braces
set showmatch
" Matching angle brackets for metaprograms
set matchpairs+=<:>

" Ignore compiled files
set wildignore=*.o,*~,*.pyc

" Show trailing whitespaces.
set list
set listchars=tab:>.,trail:.,extends:#,nbsp:.

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

" Ensure that the viminfo file is hidden after a leave
" (This is NOT automatic on Windows...)
if has("win32")
  autocmd VimLeave * !attrib +h ~/.viminfo
elseif has("unix")
  " But when ran in Git Bash, it is NOT a 'win32' environment...
  autocmd VimLeave * !if [ "$(type -t attrib)" == 'file' ]; then attrib +h ~/.viminfo; fi
endif

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
nnoremap <F2> :buffers<CR>:buffer<Space>
nnoremap <F3> :bprevious <CR>
nnoremap <F4> :bnext <CR>

" Close the current buffer.
command Bc bp|bd#

" Clear highlighted searches.
command C let @/=""

" Quickly turn paste mode on or off
command Pon set paste
command Poff set nopaste

" Folding control.
set nofoldenable " Off by default.
nmap <C-S-o> :foldopen <CR>
nmap <C-S-p> :foldclose <CR>

" Only do this part when compiled with support for autocommands.
if has("autocmd")
    " Use filetype detection and file-based automatic indenting.
    filetype plugin indent on

    " Use actual tab chars in Makefiles. They mess up when non tabs are used.
    autocmd FileType make set tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab
endif
