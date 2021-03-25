" indentLine
Plug 'Yggdroot/indentLine'

" Do not override the conceals set in the colourscheme.
let g:indentLine_setColors = 0

" Use same colour for other indent characters like the Vim listchars feature.
let g:indentLine_defaultGroup = 'SpecialKey'

" Use distinct indentation markers for levels
let g:indentLine_char_list = ['▏']

" Do not turn on Conceal by default.
let g:indentLine_setConceal = 0
