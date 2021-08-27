" Required dependency.
Plug 'godlygeek/tabular', { 'for': ['markdown'] }

" Vim-Markdown
Plug 'plasticboy/vim-markdown', { 'for': ['markdown'] }

if has("autocmd")
    augroup MarkdownFormat
        " Remove old commands and add the current ones to the group only.
        " As per the documentation, see `:help augroup`.
        au!

        autocmd FileType markdown nnoremap <buffer> <LocalLeader>mt :TableFormat<CR>
    augroup END
endif
