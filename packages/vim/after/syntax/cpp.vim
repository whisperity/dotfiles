scriptencoding utf-8

if !has('conceal')
    finish
endif

syntax keyword cppKeyword this conceal cchar=⌭

syntax keyword cppOperator alignof  conceal cchar=⁑
syntax keyword cppOperator decltype conceal cchar=∂

syntax match cNiceOperator "::" conceal cchar=.

syntax keyword cppType    bool  conceal cchar=𝔹
syntax keyword cppBoolean true  conceal cchar=⊤

if $TERMINAL_NAME == "contour" || !empty($GNOME_TERMINAL_SCREEN)
    " Real \bot for the falsum.
    syntax keyword cppBoolean false conceal cchar=⊥
elseif !empty($KONSOLE_DBUS_SERVICE)
    " The real \bot symbol is randomly broken in Konsole, so use \perp instead.
    syntax keyword cppBoolean false conceal cchar=⟂
else
    syntax keyword cppBoolean false conceal cchar=⟂
endif

syntax keyword cppKeyword NULL nullptr conceal cchar=∅

syntax keyword cppStructure template conceal cchar=⛏
syntax keyword cppStructure typename conceal cchar=⌥

hi link cppKeyword  Keyword
hi link cppOperator Operator
hi link cppBoolean  Boolean
