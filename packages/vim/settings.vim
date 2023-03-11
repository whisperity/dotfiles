" Main Vim/Neovim configuration file.
" This file should contain only the configuration options that are supported
" by **stock** (n)vim. Individual plugins should be configured in their own
" configuration files.
let vimRootPath = expand($HOME . "/.vim")

" '\' for Leader and LocalLeader are tedious on huHU layout.
let mapleader = ","
let maplocalleader = ","

" Neovim
if has('nvim')
  tnoremap <C-c><C-c> <C-\><C-n>

  let &shadafile = vimRootPath . "/nvim.shada"
else
  let &viminfofile = vimRootPath . "/viminfo/vim.viminfo"
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
" Just simply do not use the Right-click menu idiocity...
if has('nvim')
  set mousemodel=extend
endif

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
set wildignore=*.o,*.out,*.so,*~,*.pyc

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

" Destroy all buffers that are not currently visible anywhere and don't
" contain changes.
function! DeleteOldBuffers()
    let l:buffers = filter(getbufinfo(), {_, v -> (!v.loaded || v.hidden) && (!v.changed)})
    if !empty(l:buffers)
        exec 'bwipeout' join(map(l:buffers, {_, v -> v.bufnr}))
    endif
endfunction
nnoremap <silent> <C-c><C-x> :call DeleteOldBuffers()<CR>

" Clear highlighted searches.
command! C let @/=""
" <Ctrl-AltGr-g>
nmap <C-]> :noh<CR>

" Auto-apply the macro stored in 'q' (created by pressing qq).
nmap <silent> <Space> @q

" Quickly turn paste mode on or off
function! TogglePasteEnable()
    if &paste == 1
        setlocal nopaste
    else
        setlocal paste
    endif
endfunction
nnoremap <silent> <C-c><C-p> :call TogglePasteEnable()<CR>

" Folding control.
if has('folding')
  set nofoldenable " Off by default.
  set foldmethod=manual
  function! ToggleFoldingEnable()
      if &foldenable == 1
          setlocal nofoldenable
          setlocal foldmethod=manual

          unmap <buffer> <S-f>
      else
          setlocal foldenable
          setlocal foldmethod=syntax

          nnoremap <buffer> <silent> <S-f> za
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

" Crosshair
set nocursorcolumn nocursorline
function! ToggleCrosshair()
    if &cursorcolumn == 0
        setlocal cursorcolumn cursorline
    else
        setlocal nocursorcolumn nocursorline
    endif
endfunction
nnoremap <silent> <C-c><C-v> :call ToggleCrosshair()<CR>

" Only do this part when compiled with support for autocommands.
if has("autocmd")
    " Use filetype detection and file-based automatic indenting.
    filetype plugin indent on

    augroup FiletypeDefaults
        " Remove old commands and add the current ones to the group only.
        " As per the documentation, see `:help augroup`.
        au!

        " Use actual <Tab> chars in Makefiles. They mess up when spaces are used!
        autocmd FileType make setlocal tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab

        " Spell checking for papers and various human text things.
        autocmd FileType tex,latex,context,plaintex,bib setlocal spell spelllang=en_gb
        autocmd FileType markdown,rst setlocal spell spelllang=en_gb
    augroup END
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
autocmd! User PlugPostSetup

" Load configuration files and install directives for plugins.
for f in split(glob('~/.vim/config/*.vim'), '\n')
    exe 'source' f
endfor



" Show file-type icons to various plugins, like statusline, NERDTree,
" Explorer, etc.
" This plugin is expected to **ALWAYS** be loaded last, unfortunately.
Plug 'ryanoasis/vim-devicons'



" Initialize plugin system.
" This is the call that actually starts downloading the plugins and hits the
" load calls...
call plug#end()

" Execute the post-load hooks for every plugin.
" We are rolling a custom implementation here because VimPlug, by itself, only
" offers the hook if Vim-Plug is loading something on-demand, which means it
" is not usable for always-loaded (or by-VimPlug-not-loadable, e.g.,
" Lua-based) plugins...
"
" See http://github.com/junegunn/vim-plug/issues/1134
doautoall <nomodeline> User PlugPostSetup
