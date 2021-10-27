" VimSpector
Plug 'puremourning/vimspector'

let g:vimspector_install_gadgets = [ 'debugpy', 'vscode-cpptools' ]

" Actually, start or continue.
nmap <F5>             <Plug>VimspectorContinue
nmap <LocalLeader>dS  <Plug>VimspectorStop
if has('nvim')
    " F29 = C-F5
    nmap <F29>        <Plug>VimspectorStop
endif
nmap <LocalLeader>dx  :VimspectorReset<CR>
nmap <LocalLeader>dr  <Plug>VimspectorRestart
nmap <LocalLeader>dp  <Plug>VimspectorPause

nmap <LocalLeader>di  <Plug>VimspectorBalloonEval
xmap <LocalLeader>di  <Plug>VimspectorBalloonEval

nmap <LocalLeader>db  <Plug>VimspectorToggleBreakpoint
nmap <LocalLeader>dB  <Plug>VimspectorToggleConditionalBreakpoint

nmap <F11>            <Plug>VimspectorStepInto
nmap <LocalLeader>dso <Plug>VimspectorStepOut
nmap <LocalLeader>dsr <Plug>VimspectorStepOver
if has('nvim')
    " F23 = S-F11
    nmap <F23>        <Plug>VimspectorStepOver
    " F35 = C-F11
    nmap <F35>        <Plug>VimspectorStepOut
endif

nmap <LocalLeader>dk <Plug>VimspectorUpFrame
nmap <LocalLeader>dj <Plug>VimspectorDownFrame
