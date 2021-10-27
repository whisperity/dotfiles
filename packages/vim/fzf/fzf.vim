" FuzzyFinder (fzf).
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Always enable preview window on the right with 60% width.
let g:fzf_preview_window = 'right:60%'
let $FZF_DEFAULT_OPTS='--reverse'

function! s:fzf_files_handler(lines) abort
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

" Return the second column of a "git status -s" output.
function! s:git_status_cleanup(line) abort
  return get(filter(split(a:line, " "), 'v:val != ""'), 1)
endfunction

function! s:fzf_git_handler(lines) abort
  if empty(a:lines)
    return
  endif
  let cmd = get({ 'ctrl-t': 'tabedit',
                \ 'ctrl-x': 'split',
                \ 'ctrl-v': 'vsplit' }, remove(a:lines, 0), 'e')

  for item in a:lines
    " Cut the Git status tags (first column)
    let item = s:git_status_cleanup(item)
    execute cmd escape(item, ' %#\')
  endfor
endfunction

" Search all files. (Same as ^t in Zsh.)
nmap <silent> <C-t> :call fzf#run({
  \ 'options': '--multi --expect=ctrl-t,ctrl-x,ctrl-v',
  \ 'window':  {'width': 0.9, 'height': 0.6},
  \ 'sink*':   function('<sid>fzf_files_handler')})<CR>

" Search the files that changed in version control.
" (Same as ^g in Zsh.)
nmap <silent> <C-g> :call fzf#run({
  \ 'source': 'git status -s',
  \ 'options': '--multi --expect=ctrl-t,ctrl-x,ctrl-v',
  \ 'window':  {'width': 0.9, 'height': 0.6},
  \ 'sink*':   function('<sid>fzf_git_handler')})<CR>

" Remap the buffer searcher if this plugin is loaded.
nmap <silent> <F2> :Buffers<CR>

" Remap the tab switcher if this plugin is loaded.
nmap <silent> <Leader>tt :Windows<CR>

" Remap the default Vim command search sequence.
nmap <silent> q: :History:<CR>

" Search in the contents of all files.
nmap <silent> <Leader>ff :Ag<CR>

" Search the saved markers.
nmap <silent> <Leader>fm :Marks<CR>

" Search in the contents of the current file. (Similar to ^f in Zsh.)
nmap <silent> <C-f> :BLines<CR>
