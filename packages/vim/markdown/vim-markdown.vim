" Vim-Markdown
Plug 'godlygeek/tabular', { 'for': ['markdown'] }
Plug 'plasticboy/vim-markdown', { 'for': ['markdown'] }



" Preview Markdown documents in a browser.
"
" If you don't have nodejs and yarn
" use pre build, add 'vim-plug' to the filetype list so vim-plug can update this plugin
" see: https://github.com/iamcco/markdown-preview.nvim/issues/50
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}



" Preview Markdown documents inside Vim itself.
" (Note: Unfortunately does not work well, no document scrolling...)
" Plug 'skanehira/preview-markdown.vim', { 'for': ['markdown'] }
" let g:preview_markdown_auto_update = 1
" let g:preview_markdown_parser = 'glow'



if has("autocmd")
    augroup MarkdownFormat
        " Remove old commands and add the current ones to the group only.
        " As per the documentation, see `:help augroup`.
        au!

        autocmd FileType markdown nnoremap <buffer> <C-f> :TableFormat<CR>
        autocmd FileType markdown nnoremap <buffer> <LocalLeader>mm :MarkdownPreview<CR>
    augroup END
endif
