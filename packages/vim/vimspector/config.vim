" Vimspector keybinds.

" Actually, start or continue.
nmap <F5>            <Plug>VimspectorContinue
nmap <C-F5>          <Plug>VimspectorStop
nmap <LocalLeader>dx :VimspectorReset <CR>
nmap <LocalLeader>dr <Plug>VimspectorRestart
nmap <LocalLeader>dp <Plug>VimspectorPause

nmap <LocalLeader>di <Plug>VimspectorBalloonEval
xmap <LocalLeader>di <Plug>VimspectorBalloonEval

nmap <C-b>   <Plug>VimspectorToggleBreakpoint
nmap <C-S-b> <Plug>VimspectorToggleConditionalBreakpoint

nmap <F11>   <Plug>VimspectorStepInto
nmap <S-F11> <Plug>VimspectorStepOver
nmap <C-F11> <Plug>VimspectorStepOut
