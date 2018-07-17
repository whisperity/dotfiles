" Pathogen
if has('nvim')
  " My nvim is compiled without python2 support atm.
  let g:pathogen_disabled = ['YouCompleteMe']
endif

" Neovim
if has('nvim')
  tnoremap <Esc> <C-\><C-n>
endif

" YCM
let g:ycm_confirm_extra_conf = 0
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1

