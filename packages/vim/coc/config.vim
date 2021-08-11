" CoC.nvim
Plug 'neoclide/coc.nvim', {'branch': 'release'}

let g:coc_disable_startup_warning = 1
let g:coc_config_home = "~/.vim/config/"
let g:coc_data_home = "~/.vim/coc.nvim"

" Load (and most importantly, install!) some useful extensions by default.
let g:coc_global_extensions = [
        \'coc-clangd',
        \'coc-explorer',
        \'coc-json',
        \'coc-pyright',
        \'coc-vimtex',
        \'coc-yaml',
        \]

let g:coc_popup_conceal_disable = 1

nmap <silent> <C-n> :CocCommand explorer<CR>

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

augroup CocGroup
    " Delete existing autocommands in the group at config reload (as per
    " :help augroup).
    au!

    " Echo signature help of current function.
    autocmd User CocJumpPlaceholder call
                            \ CocActionAsync('showSignatureHelp')

    " Have the ability to jump between the source file and the associated
    " header file.
    autocmd FileType c,cpp,objc,objcpp,javascript nnoremap <silent><buffer> <LocalLeader>yh :CocCommand clangd.switchSourceHeader<CR>
augroup END

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



" Show file-type icons to various plugins, but most importantly CocExplorer.
Plug 'ryanoasis/vim-devicons'




" Semantic highlight for C++ code.
Plug 'jackguo380/vim-lsp-cxx-highlight', { 'for': ['c', 'cpp', 'objc', 'objcpp'] }




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
