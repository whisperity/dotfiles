" Clang Format
Plug 'rhysd/vim-clang-format', { 'for': ['c', 'cpp', 'objc', 'objcpp', 'javascript'] }

let g:clang_format#code_style = 'llvm'

if has("autocmd")
    augroup ClangFormat
        " Remove old commands and add the current ones to the group only.
        " As per the documentation, see `:help augroup`.
        au!

        autocmd FileType c,cpp,objc,objcpp,javascript vnoremap <buffer><C-f> :ClangFormat<CR>
    augroup END
endif
