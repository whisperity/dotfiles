" VimTeX
Plug 'lervag/vimtex', { 'for': ['tex', 'latex', 'context', 'plaintex'] }

let g:tex_flavor = 'latex'

" Allow -shell-escape to be passed, e.g. for "minted" highlighting.
let g:vimtex_compiler_latexmk = {
    \ 'options' : [
    \   '-shell-escape',
    \   '-verbose',
    \   '-file-line-error',
    \   '-synctex=1',
    \   '-interaction=nonstopmode',
    \ ],
    \}

" Use emoji to conceal citations.
let g:vimtex_syntax_conceal_cites = {
    \ 'type': 'icon',
    \ 'icon': '📖'
    \}
