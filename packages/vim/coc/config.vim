" coc.nvim

let g:coc_config_home = "~/.vim/config/"
let g:coc_data_home = "~/.vim/coc-root"

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

"Echo signature help of current function.
autocmd User CocJumpPlaceholder call
                        \ CocActionAsync('showSignatureHelp')

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

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

nmap <silent> <LocalLeader>ye :CocDiagnostics<CR>
nmap <silent> <LocalLeader>yi :CocInfo<CR>
nmap <silent> <LocalLeader>yy :CocRestart<CR>
