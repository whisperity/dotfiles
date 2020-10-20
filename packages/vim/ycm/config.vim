" YCM

let g:ycm_auto_trigger = 1
let g:ycm_filetype_whitelist = {
    \ 'c': 1,
    \ 'cpp': 1,
    \ 'python': 1
    \ }

let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1

let g:ycm_global_ycm_extra_conf = $HOME."/.vim/ycm_extra_conf.py"

let g:ycm_clangd_binary_path = exepath("clangd")
let g:ycm_clangd_uses_ycmd_caching = 0
let g:ycm_clangd_args = ["-log=verbose", "-pretty", "--background-index", "-j=4"]

let g:ycm_key_invoke_completion = '<C-Space>'
let g:ycm_key_stop_completion = ['<C-e>']

nmap <LocalLeader>yh :YcmCompleter GoToInclude<CR>
nmap <LocalLeader>yd :YcmCompleter GoToDefinition<CR>
nmap <LocalLeader>yu :YcmCompleter GoToReferences<CR>
nmap <LocalLeader>yc :YcmCompleter GetDoc<CR>
nmap <LocalLeader>yt :YcmCompleter GetType<CR>

nmap <LocalLeader>ye :YcmDiags<CR>
nmap <LocalLeader>yy :YcmRestartServer<CR>
nmap <LocalLeader>yi :YcmDebugInfo<CR>
nmap <LocalLeader>yo :YcmToggleLogs<CR>

