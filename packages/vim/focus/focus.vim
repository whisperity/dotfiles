" Focused writing (hide everything)
Plug 'junegunn/goyo.vim'

" FIXME: :ContextToggle when entering and leaving Goyo, and
" call :Goyo! (leave Goyo forcibly) before Startify saves the session.

nnoremap <silent> <C-c><C-g> :Goyo<CR>



" Focused writing (shadow outside context)
Plug 'junegunn/limelight.vim'

" Shadow multiplier (default 0.5)
let g:limelight_default_coefficient = 0.75

" Number of preceding/following paragraphs to include (default: 0)
let g:limelight_paragrap_scan = 1

nnoremap <silent> <C-c><C-l> :Limelight!!<CR>



" Automatic focus (resize splits when moving the cursor)
if has('nvim')
  " Only works with NeoVim as it needs Lua...
  Plug 'beauwilliams/focus.nvim'

  function! s:loadFocusNvim()
    " Leave everything related to the inner look of the splits as is!
    lua require("focus").setup({
          \ colorcolumn = { enable = false },
          \ cursorline = false,
          \ cursorcolumn = false,
          \ signcolumn = false,
          \ number = false,
          \ relativenumber = false,
          \ hybridnumber = false,
          \ })
    call add(g:startify_session_savecmds, "FocusEnable")

    " Silence some errors related to calculation when loading a session.
    " focus.nvim will take control over anyway.
    " call add(g:startify_session_remove_lines, "winheight")
    " call add(g:startify_session_remove_lines, "winminheight")
    " call add(g:startify_session_remove_lines, "winminwidth")
    call add(g:startify_session_remove_lines, "set winheight")
    call add(g:startify_session_remove_lines, "set winwidth")


    " Reset the size of the windows when exiting, so the reload of the session
    " does not cause errors.
    call add(g:startify_session_before_save, "FocusEqualise")
    call add(g:startify_session_before_save, "FocusDisable")
  endfunction

  augroup Load__FocusNVim
    autocmd!
    " When this file (focus.vim) is 'source'd the Lua stuff is not available
    " yet, so calling require("focus") here would make the system explode.
    " Instead, register a hook that will call the setup for us. This is a
    " **CUSTOM** hook, vim-plug by itself does not expose such hooks,
    " unfortunately.
    autocmd User PlugPostSetup call s:loadFocusNvim()
  augroup END
endif
