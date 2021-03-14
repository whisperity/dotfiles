" Vista

let g:vista_default_executive = 'coc'

let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]

let g:vista_fzf_preview = ['right:30%']

" Show the symbols on the left.
let g:vista_sidebar_position = "vertical topleft"

let g:vista_close_on_jump = 1

nmap <silent> <LocalLeader>yt :Vista!!<CR>
nmap <silent> <LocalLeader>yf :Vista finder<CR>
