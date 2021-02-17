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
syntax keyword cStructure struct conceal cchar=𝐒
syntax keyword cStructure class  conceal cchar=§
syntax keyword cOperator  sizeof conceal cchar=∡

syntax keyword cStatement return conceal cchar=⏎
syntax keyword cStatement goto   conceal cchar=↷

syntax keyword cRepeat while    conceal cchar=⥁
syntax keyword cRepeat for      conceal cchar=∀
syntax keyword cRepeat continue conceal cchar=↻
syntax keyword cRepeat break    conceal cchar=⏻

syntax keyword cConditional if        conceal cchar=▸
" Unfortunately, "else if" is prefixed by "else", so we can't have nice things.
"syntax keyword cConditional else      conceal cchar=▹
syntax keyword cConditional else      conceal cchar=▪

syntax keyword cType void              conceal cchar=∅
syntax keyword cType bool              conceal cchar=𝔹
syntax keyword cType unsigned          conceal cchar=ℕ
syntax keyword cType int short long    conceal cchar=ℤ
syntax keyword cType char              conceal cchar=∁
syntax keyword cType float double      conceal cchar=ℝ
syntax keyword cType str string        conceal cchar=𝐒

syntax keyword cConstant false        conceal cchar=⟂
syntax keyword cConstant FALSE        conceal cchar=⟂
" The real \bot symbol is broken in Konsole so use \perp instead.
"syntax keyword cConstant false        conceal cchar=⊥
"syntax keyword cConstant FALSE        conceal cchar=⊥
syntax keyword cConstant true         conceal cchar=⊤
syntax keyword cConstant TRUE         conceal cchar=⊤
syntax keyword cConstant NULL         conceal cchar=∅

syntax keyword cKeyword complex      conceal cchar=ℂ
syntax keyword cKeyword bool         conceal cchar=𝔹
syntax keyword cKeyword const        conceal cchar=𝌸
syntax keyword cKeyword volatile     conceal cchar=☢
syntax keyword cKeyword this         conceal cchar=⌭

syntax keyword cKeyword assert       conceal cchar=‽

hi link cNiceOperator Operator
hi link cKeyword      Keyword
hi link cBoolean      Boolean
