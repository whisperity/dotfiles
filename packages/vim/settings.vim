let vimRootPath = expand($HOME . "/.vim")

" Neovim
if has('nvim')
  tnoremap <C-c><C-c> <C-\><C-n>

  let &shadafile = vimRootPath . "/nvim.shada"
else
  let &viminfofile = vimRootPath . "/vim.viminfo"
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

" Do not enter Ex mode
" http://www.bestofvim.com/tip/leave-ex-mode-good/
nnoremap <silent> Q <nop>

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

" incremental search
set incsearch

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

set shiftwidth=4
set tabstop=2

set smarttab

" Matching braces
set showmatch
" Matching angle brackets for metaprograms
set matchpairs+=<:>

" Ignore compiled files
set wildignore=*.o,*~,*.pyc

" Show surrounding whitespaces.
set list
set listchars=tab:>.,trail:.,extends:#,nbsp:.

" Control the position of the new window
set splitbelow
set splitright

" No annoying sound on errors
"set noerrorbells
"set novisualbell

" Turn backup off, since most stuff is in SVN, Git, etc. anyway...
"set nobackup
"set nowb
"set noswapfile

" Put the swap file near the edited file.
set directory=.

" Smart way to move between windows
map <silent> <C-j> <C-W>j
map <silent> <C-k> <C-W>k
map <silent> <C-h> <C-W>h
map <silent> <C-l> <C-W>l

" Force yourself to learn H, J, K, L instead of arrow keys.
"map <silent> <up> <nop>
"map <silent> <down> <nop>
"map <silent> <left> <nop>
"map <silent> <right> <nop>

noremap <buffer> <silent> k gk
noremap <buffer> <silent> j gj
noremap <buffer> <silent> gk k
noremap <buffer> <silent> gj j

" Buffer switch.
nnoremap <F2>          :buffers<CR>:buffer<Space>
nnoremap <silent> <F3> :bprevious<CR>
nnoremap <silent> <F4> :bnext<CR>

" Tab switch.
nnoremap <Leader>tt          :tabs<CR>:tabnext<Space>
nnoremap <silent> <Leader>tc :tabclose<CR>

" Close the current buffer.
command! Bc bp|bd#
nnoremap <silent> <C-x> :Bc<CR>

" Clear highlighted searches.
command! C let @/=""

" Quickly turn paste mode on or off
command! Pon set paste
command! Poff set nopaste

" Folding control.
if has('folding')
  set nofoldenable " Off by default.
  set foldmethod=manual
  function! ToggleFoldingEnable()
      if &foldenable == 1
          setlocal nofoldenable
          setlocal foldmethod=manual

          unmap <buffer> <Space>
      else
          setlocal foldenable
          setlocal foldmethod=syntax

          " Use SPACE to toggle folds.
          nnoremap <buffer> <silent> <Space> za
      endif
  endfunction
  nnoremap <silent> <C-c><C-f> :call ToggleFoldingEnable()<CR>
endif

" Concealment of symbols.
if has('conceal')
  set concealcursor=nc
  set conceallevel=0

  function! ToggleConcealLevel()
      if &conceallevel == 0
          setlocal conceallevel=2
      else
          setlocal conceallevel=0
      endif
  endfunction
  nnoremap <silent> <C-c><C-y> :call ToggleConcealLevel()<CR>
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")
    " Use filetype detection and file-based automatic indenting.
    filetype plugin indent on

    " Use actual <Tab> chars in Makefiles. They mess up when spaces are used!
    autocmd FileType make setlocal tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab

    " Spell checking for papers and various human text things.
    autocmd FileType tex,latex,context,plaintex,bib setlocal spell spelllang=en_gb
    autocmd FileType markdown,rst setlocal spell spelllang=en_gb
endif


" Install vim-plug if not found...
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -sfLo ~/.vim/autoload/plug.vim --create-dirs
    \ http://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

" Run PlugInstall if there are missing plugins.
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif


" Start loading the packages with VimPlug!
call plug#begin('~/.vim/bundle')

" Load configuration files and install directives for plugins.
for f in split(glob('~/.vim/config/*.vim'), '\n')
    exe 'source' f
endfor

" Initialize plugin system.
call plug#end()
