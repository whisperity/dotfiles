" Clang Format
Plug 'rhysd/vim-clang-format', { 'for': ['c', 'cpp', 'objc', 'objcpp', 'javascript'] }

let g:clang_format#code_style = 'llvm'

if has("autocmd")
  autocmd FileType c,cpp,objc,objcpp,javascript vnoremap <buffer><C-f> :ClangFormat<CR>
endif
