" Vim-Workspace
Plug 'thaerkh/vim-workspace'

" Save the session information in the Vim directory.
let workspaceSessionPath = expand($HOME . "/.vim/sessions/")
silent execute '!mkdir -p ' . workspaceSessionPath
let g:workspace_session_directory = workspaceSessionPath

" Do not autosave on exit.
let g:workspace_autosave = 0

" Do not load sessions when opening a file explicitly.
let g:workspace_session_disable_on_args = 1

" Do not persist undo history through this plugin, we have separate plugins
" and configuration for that.
let g:workspace_persist_undo_history = 0
