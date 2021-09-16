" Install some Vim plugins that are mostly always needed.
Plug 'jlanzarotta/bufexplorer', { 'on': [
            \ 'BufExplorer',
            \ 'BufExplorerHorizontalSplit',
            \ 'BufExplorerVerticalSplit'
            \ ] }
Plug 'wellle/context.vim'
Plug 'bogado/file-line'
Plug 'danro/rename.vim', { 'on': 'Rename' }
Plug 'ntpeters/vim-better-whitespace'
Plug 'machakann/vim-highlightedyank'
Plug 'farmergreg/vim-lastplace'

Plug 'xolox/vim-misc' | Plug 'xolox/vim-reload'



" AutoPairs - automatically close paren-bracket sequences on opening.
Plug 'jiangmiao/auto-pairs'
let g:AutoPairsFlyMode = 0



" ChooseWin.
Plug 't9md/vim-choosewin', { 'on': '<Plug>(choosewin)' }

" Invoke with '-'.
nmap - <Plug>(choosewin)

" Do not do anything if only one window is open. Unfortunately, it makes
" tab handling broken, as the tab chooser won't show up either.
let g:choosewin_return_on_single_win = 0

" Show the letters on the overlay.
let g:choosewin_overlay_enable = 0
let g:choosewin_overlay_shade = 1
let g:choosewin_color_overlay = {
      \ 'gui': ['DodgerBlue3', 'DodgerBlue3'],
      \ 'cterm': [25, 25]
      \ }
let g:choosewin_color_overlay_current = {
      \ 'gui': ['firebrick1', 'firebrick1'],
      \ 'cterm': [124, 124]
      \ }



" EditorConfig.
Plug 'editorconfig/editorconfig-vim'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']



" Startscreen and session handler.
Plug 'mhinz/vim-startify'
let g:startify_list_order = [
      \ ['   My most recently used files in the current directory:'],
      \ 'dir',
      \ ['   My most recently used files:'],
      \ 'files',
      \ ['   These are my sessions:'],
      \ 'sessions',
      \ ['   These are my bookmarks:'],
      \ 'bookmarks',
      \ ]
let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'bundle/.*/doc',
      \ ]
let g:startify_change_to_dir = 0
let g:startify_change_to_vcs_root = 1
let g:startify_update_oldfiles = 1

" Save the session information in the Vim directory.
let workspaceSessionPath = expand($HOME . "/.vim/session/")
silent execute '!mkdir -p ' . workspaceSessionPath

set sessionoptions=buffers,curdir,folds,localoptions,options,tabpages,winpos,winsize

" Settings for Startify's session handling.
let g:startify_session_autoload = 1
let g:startify_session_dir = workspaceSessionPath
" let g:startify_session_keep_options = 1
let g:startify_session_persistence = 1
let g:startify_session_sort = 0

" vim-context has to be disabled so the saved buffers don't get messed up.
let g:startify_session_before_save = [
      \ "ContextDisable"
      \ ]

" (Needed dependency for fetching Git branch information.)
Plug 'itchyny/vim-gitbranch'

" Save the session with the branch name annotated to it.
function! s:GetUniqueSessionName()
  let path = fnamemodify(getcwd(), ':p')
  let path = empty(path) ? 'UNKNOWN_PATH' : path
  let path = substitute(path, '/$', '', 'g')
  let branch = gitbranch#name()
  let branch = empty(branch) ? '' : '@' . branch
  return substitute(path . branch, '/', '%', 'g')
endfunction

function! s:IsCwdIgnoredForSession()
  if fnamemodify(getcwd(), ':~') ==# "~/"
    " Don't do anything if the user just starts a Vim in their Terminal. :)
    return 1
  endif
  if filereadable("Session.vim")
    return 1
  endif

  return 0
endfunction

function! s:LoadSession()
  if s:IsCwdIgnoredForSession()
    return
  endif

  " Load the crafted session name.
  execute 'SLoad ' . s:GetUniqueSessionName()
endfunction

function! s:SaveSession()
  if s:IsCwdIgnoredForSession()
    return
  endif

  " Save with the crafted session name.
  execute 'SSave! ' . s:GetUniqueSessionName()
endfunction

augroup Startify
  autocmd!
  autocmd User        StartifyReady call s:LoadSession()
  autocmd VimLeavePre *             call s:SaveSession()
augroup END



" ToggleCursor.
Plug 'jszakmeister/vim-togglecursor'
if !has("nvim")
    " Do whatever is needed to detect your terminal.  Many times, this is
    " a simple check of the $TERM or $TERM_PROGRAM environment variables.
    if $TERMINAL_NAME ==? "contour"
        " Set the kind of escape sequences to use.  Most use xterm-style
        " escaping, there are a few that use the iterm (CursorShape) style
        " sequences.  The two acceptable values to use here are: 'xterm'
        " and 'iterm'.
        let g:togglecursor_force = "xterm"
    elseif !empty("$KONSOLE_DBUS_SERVICE")
        " Konsole is stupid, and will mess up profiles from the escape
        " sequences emitted by the plugin.

        " Make-belive that the plugin has already loaded.
        let g:loaded_togglecursor = 2
    endif

    " Use I-Beam in default mode.
    let g:togglecursor_default = "line"

    " Use blinking line for insertion.
    let g:togglecursor_insert = "blinking_line"

    " Revert back to I-Beam cursor in the terminal after leave.
    let g:togglecursor_leave = "blinking_line"
else
    " ToggleCursor doesn't work for NeoVim, so we need to configure nvim
    " normally.
    let g:togglecursor_disable_neovim = 1
    set guicursor=v-c-sm:block,n-ci-ve:ver25,o:hor20,i:ver25-blinkon500,r:hor20-blinkon500

    " At exit, restore the blinking I-Beam.
    autocmd VimLeave * set guicursor=a:ver25-blinkon500
endif
