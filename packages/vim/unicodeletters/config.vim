" Prevent throwing out the normal binds (especially C-l for the window switch)
let g:unicoder_no_map = 1

" Use Ctrl-L for LaTeX symbol in input and select modes.
inoremap <silent> <C-l> <Esc>:call unicoder#start(1)<CR>
vnoremap <silent> <C-l> :<C-u>call unicoder#selection()<CR>
