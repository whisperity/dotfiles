" Forked from http://github.com/alok/c-conceal
scriptencoding utf-8

" We need the conceal feature (vim ≥ 7.3)
if !has('conceal')
    finish
endif

syntax match cNiceOperator "++" conceal cchar=Δ
syntax match cNiceOperator "--" conceal cchar=∇

" These are usually taken over by the ligatures of the font used.
"syntax match cNiceOperator "==" conceal cchar=≝
"syntax match cNiceOperator "!=" conceal cchar=≠
"syntax match cNiceOperator ">=" conceal cchar=≥
"syntax match cNiceOperator "<=" conceal cchar=≤
"
"syntax match cNiceOperator "->" conceal cchar=➞

syntax match cNiceOperator "&&" conceal cchar=∧
syntax match cNiceOperator "||" conceal cchar=∨

syntax match cNiceOperator "<<" conceal cchar=≺
syntax match cNiceOperator ">>" conceal cchar=≻

syntax match cNiceOperator "!" conceal cchar=¬

"syntax match cNiceOperator /\s=\s/ms=s+1,me=e-1 conceal cchar=←
"syntax match cNiceOperator /\S=\S/ms=s+1,me=e-1 conceal cchar=←


syntax keyword cStructure enum   conceal cchar=∩
syntax keyword cStructure union  conceal cchar=⋃
syntax keyword cStructure struct conceal cchar=¶
syntax keyword cStructure class  conceal cchar=§
syntax keyword cOperator  sizeof conceal cchar=∡

syntax keyword cStatement return conceal cchar=⏎
syntax keyword cStatement goto   conceal cchar=↷

syntax keyword cRepeat while    conceal cchar=⥁
syntax keyword cRepeat for      conceal cchar=∀
syntax keyword cRepeat continue conceal cchar=↻
syntax keyword cRepeat break    conceal cchar=⏻

syntax clear   cConditional
syntax keyword cConditional switch        conceal cchar=⌥
" Make sure that "else if" is rendered differently than "else" + "if".
" Thanks to @lervag on GitHub for figuring this out.
syntax match   cConditional "\<if\>"      conceal cchar=▸
syntax match   cConditional "\<else\>"    conceal cchar=▪
syntax match   cConditional "\<else if\>" conceal cchar=▹

syntax keyword cType void              conceal cchar=∅
syntax keyword cType bool              conceal cchar=𝔹
syntax keyword cType unsigned          conceal cchar=ℕ
syntax keyword cType int short long    conceal cchar=ℤ
syntax keyword cType char              conceal cchar=∁
syntax keyword cType float double      conceal cchar=ℝ
syntax keyword cType str string        conceal cchar=𝐒

if $TERMINAL_NAME == "contour" || !empty($GNOME_TERMINAL_SCREEN)
    " Real \bot for the falsum.
    syntax keyword cConstant false        conceal cchar=⊥
    syntax keyword cConstant FALSE        conceal cchar=⊥
elseif !empty($KONSOLE_DBUS_SERVICE)
    " The real \bot symbol is randomly broken in Konsole, so use \perp instead.
    syntax keyword cConstant false        conceal cchar=⟂
    syntax keyword cConstant FALSE        conceal cchar=⟂
else
    syntax keyword cConstant false        conceal cchar=⟂
    syntax keyword cConstant FALSE        conceal cchar=⟂
endif
syntax keyword cConstant true         conceal cchar=⊤
syntax keyword cConstant TRUE         conceal cchar=⊤
syntax keyword cConstant NULL         conceal cchar=∅

syntax keyword cKeyword complex      conceal cchar=ℂ
syntax keyword cKeyword const        conceal cchar=𝌸
syntax keyword cKeyword volatile     conceal cchar=☢

syntax keyword cKeyword assert       conceal cchar=‽

hi link cNiceOperator Operator
hi link cKeyword      Keyword
hi link cBoolean      Boolean
