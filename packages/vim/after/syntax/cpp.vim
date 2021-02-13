scriptencoding utf-8

if !has('conceal')
    finish
endif

syntax keyword cppOperator alignof  conceal cchar=⁑
syntax keyword cppOperator decltype conceal cchar=∂

syntax match cNiceOperator "::" conceal cchar=.

syntax keyword cppType bool     conceal cchar=𝔹
syntax keyword cppBoolean false conceal cchar=⟂
syntax keyword cppBoolean true  conceal cchar=⊤

syntax keyword cppKeyword NULL nullptr conceal cchar=∅

hi link cppKeyword  Keyword
hi link cppOperator Operator
hi link cppBoolean  Boolean
