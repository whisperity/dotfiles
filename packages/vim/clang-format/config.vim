" Clang Format
let g:clang_format#code_style = 'llvm'

if has("autocmd")
  autocmd FileType c vnoremap <C-f> :ClangFormat<cr>
  autocmd FileType cpp vnoremap <C-f> :ClangFormat<cr>
endif
