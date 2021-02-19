" FuzzyFinder (fzf).

" Add FZF's root to the Vim path so scripts are picked up.
set runtimepath+=~/.vim/fzf-root

" Always enable preview window on the right with 60% width.
let g:fzf_preview_window = 'right:60%'
let $FZF_DEFAULT_OPTS='--reverse'

function! s:my_fzf_handler(lines) abort
  if empty(a:lines)
    return
  endif
  let cmd = get({ 'ctrl-t': 'tabedit',
                \ 'ctrl-x': 'split',
                \ 'ctrl-v': 'vsplit' }, remove(a:lines, 0), 'e')
  for item in a:lines
    execute cmd escape(item, ' %#\')
  endfor
endfunction

" Search the files that changed in version control.
" (Same as ^g in Zsh.)
nnoremap <silent> <C-g> :call fzf#run({
  \ 'source': 'git status -s',
  \ 'options': '--expect=ctrl-t,ctrl-x,ctrl-v',
  \ 'window':  {'width': 0.9, 'height': 0.6},
  \ 'sink*':   function('<sid>my_fzf_handler')})<cr>

" Search all files. (Same as ^t in Zsh.)
nnoremap <silent> <C-t> :call fzf#run({
  \ 'options': '--expect=ctrl-t,ctrl-x,ctrl-v',
  \ 'window':  {'width': 0.9, 'height': 0.6},
  \ 'sink*':   function('<sid>my_fzf_handler')})<cr>

" Remap the buffer searcher if this plugin is loaded.
nnoremap <silent> <F2> :Buffers<cr>

" Remap the default Vim command search sequence.
nnoremap <silent> q: :History:<cr>

" Search in the contents of all files.
nnoremap <silent> <localleader>ff :Ag<cr>

" Search in the contents of the current file. (Similar to ^f in Zsh.)
nnoremap <silent> <C-f> :BLines<cr>
