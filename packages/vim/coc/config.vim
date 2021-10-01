" CoC.nvim
Plug 'neoclide/coc.nvim', {'branch': 'release'}

let g:coc_disable_startup_warning = 1
let g:coc_config_home = "~/.vim/config/"
let g:coc_data_home = "~/.vim/coc.nvim"

" Load (and most importantly, install!) some useful extensions by default.
let g:coc_global_extensions = [
        \ 'coc-cmake',
        \ 'coc-clangd',
        \ 'coc-explorer',
        \ 'coc-highlight',
        \ 'coc-json',
        \ 'coc-pyright',
        \ 'coc-snippets',
        \ 'coc-vimtex',
        \ 'coc-yaml',
        \ ]

let g:coc_popup_conceal_disable = 1

nmap <silent> <C-n> :CocCommand explorer<CR>

" Use Tab for trigger completion with characters ahead and navigate.
"
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
"
" When a snippet with multiple placeholders is already inserted (e.g. function
" calls), use Tab and Shift-Tab to navigate between the placeholders back and
" forth.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ coc#expandableOrJumpable() ?
      \ "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

let g:coc_snippet_next = '<Tab>'
let g:coc_snippet_prev = '<S-Tab>'

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction


" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

if has("autocmd")
    augroup CocGroup
        " Delete existing autocommands in the group at config reload (as per
        " `:help augroup`).
        au!

        " Echo signature help of current function.
        autocmd User CocJumpPlaceholder call
                                \ CocActionAsync('showSignatureHelp')

        " Highlight the symbol and its references when holding the cursor.
        autocmd CursorHold * silent call CocActionAsync('highlight')

        autocmd ColorScheme *
                 \   highlight CocErrorHighlight   ctermfg=Red                        guibg=#dd0000 gui=bold
                 \ | highlight CocWarningHighlight ctermfg=DarkYellow cterm=underline guifg=#edb443 gui=underline
                 \ | highlight CocInfoHighlight    ctermfg=Blue       cterm=underline guifg=#005599 gui=underline
                 \ | highlight CocHighlightText    ctermbg=Blue                       guibg=#005599 gui=bold
        " \ | highlight! link Error         CocErrorHighlight

        if $TERM ==? "contour-latest"
          " Contour supports undercurlies
          autocmd ColorScheme *
                 \   highlight CocErrorHighlight   ctermfg=Red                        guibg=NONE guifg=#ee4400 guisp=#dd0000 gui=undercurl
        endif

        " Have the ability to jump between the source file and the associated
        " header file.
        autocmd FileType c,cpp,objc,objcpp,javascript
                    \   nnoremap <silent><buffer> <LocalLeader>yh :CocCommand clangd.switchSourceHeader<CR>
                    \ | nnoremap <silent><buffer> <LocalLeader>yH :CocCommand clangd.switchSourceHeader vsplit<CR>
    augroup END
endif

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction


nmap <silent> <LocalLeader>yd :call CocAction('jumpDefinition', v:false)<CR>
nmap <silent> <LocalLeader>yr :call CocAction('jumpReferences', v:false)<CR>
nmap <silent> <LocalLeader>yc :call <SID>show_documentation()<CR>

nmap <silent> <LocalLeader>ya <Plug>(coc-codeaction)
nmap <silent> <LocalLeader>ys <Plug>(coc-rename)

nmap <silent> <LocalLeader>ye :CocDiagnostics<CR>
nmap <silent> <LocalLeader>yx <Plug>(coc-fix-current)
nmap <silent> <LocalLeader>yn <Plug>(coc-diagnostic-next)
nmap <silent> <LocalLeader>yp <Plug>(coc-diagnostic-prev)

nmap <silent> <LocalLeader>yi :CocInfo<CR>
nmap <silent> <LocalLeader>yy :CocRestart<CR>



" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)



" Semantic highlight for C++ code.
Plug 'jackguo380/vim-lsp-cxx-highlight', { 'for': [
            \ 'c',
            \ 'cpp',
            \ 'objc',
            \ 'objcpp'
            \ ] }




" Vista
" Symbol browser for current file.
Plug 'liuchengxu/vista.vim'

let g:vista_default_executive = 'coc'

let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]
let g:vista_fzf_preview = ['right:30%']

" Show the symbols on the left.
let g:vista_sidebar_position = "vertical topleft"

let g:vista_close_on_jump = 1

nmap <silent> <LocalLeader>yt :Vista!!<CR>
nmap <silent> <LocalLeader>yf :Vista finder<CR>
