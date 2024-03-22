" VimTeX
Plug 'lervag/vimtex', { 'for': [
            \ 'tex',
            \ 'latex',
            \ 'context',
            \ 'plaintex'
            \ ] }

let g:tex_flavor = 'latex'

" Use XeLaTeX or LuaLaTeX as the engine.
" let g:vimtex_compiler_latexmk_engines = {
"     \ '_'                : '-xelatex',
"     \}


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

" Conceal some symbols (if the global conceal feature is enabled).
let g:vimtex_syntax_conceal = {
    \ 'accents': 1,
    \ 'ligatures': 1,
    \ 'cites': 1,
    \ 'fancy': 1,
    \ 'greek': 1,
    \ 'math_bounds': 1,
    \ 'math_delimiters': 1,
    \ 'math_fracs': 1,
    \ 'math_super_sub': 1,
    \ 'math_symbols': 1,
    \ 'sections': 1,
    \ 'styles': 1,
    \}

let g:vimtex_syntax_conceal_cites = {
    \ 'type': 'icon',
    \ 'icon': '📖'
    \}

let g:coc_global_extensions = get(g:, 'coc_global_extensions', []) + [
    \ 'coc-vimtex',
    \ ]
