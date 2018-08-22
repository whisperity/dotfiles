" Syntastic

let g:syntastic_cpp_check_header = 1
let g:syntastic_cpp_compiler_options = '-std=c++14 -Wall -Wextra'
let g:syntastic_cpp_config_file = '.config'
let g:syntastic_cpp_remove_include_errors = 1
let g:syntastic_cpp_compiler = 'clang++'

let g:syntastic_python_checkers=['python', 'pep8']
