`vim` configuration, keybinds
=============================

> :warning: **Caution!** Some of the plugins installed might *NOT* work with pure Vim, only with [neovim](http://neovim.io).

Starting Vim
------------

 * `darkvim` (default)
 * `lightvim`

Keybinds
--------

 * Programming
   - `gc`: Toggle **c**omments for selection
   - `gcc`: Toggle **c**omments for **c**urrent line
 * Navigation
   - `-`: Jump to split/window based on next letter
   - `F2`: Buffer list
   - `F3`/`F4`: Previous/next buffer
   - `\tc`: **T**ab **c**lose
   - `\tt`: Window/Tab switcher
   - `\ff`: **F**uzzy **f**ind file contents
   - `C-f`: Fuzzy **f**ind in current file
   - `C-g`: Fuzzy find **G**it versioned files
   - `C-n`: Toggle file explorer
   - `C-t`: Fuzzy find filenames
   - `C-x`: Close buffer
   - `q:`: Command history
 * Vim internals (`C-c`)
   - `C-c C-c`: Exit Terminal back to vim (Neovim only)
   - `C-c C-f`: Toggle **f**olding
   - `C-c C-u`: **U**ndo-history
   - `C-c C-y`: Toggle conceal
   - `coR`: **Co**mmand toggle **R**ainbow
 * C/C++
   - **Selection** `C-f`: `clang-format` selected text
 * coc (formerly **Y**ouCompleteMe): `<LocalLeader>y`
   - `\yc`: Documentation for **c**ode
   - `\yd`: Jump to **d**efinition
   - `\ye`: Show **e**rrors
   - `\yf`: Symbol **f**inder
   - `\yh`: Switch between **h**eader and source file (C++-only!)
   - `\yi`: System **i**nformation
   - `\yr`: Show **r**eferences
   - `\yt`: Browse **t**ags (symbol browser)
   - `\yy`: Restart server
 * vimTeX: `<LocalLeader>l`
   - `\le`: Show **e**rrors
   - `\li`: System **i**nformation
   - `\ll`: Compi**l**e and view
   - `\lt`: Browse **t**ags (document layout)
   - `\lv`: **V**iew
   - `C-l`: Unicodify LaTeX sequence
 * Vimspector: `<LocalLeader>d` - **d**ebugger
   - `F5`: Continue
   - `C-F5`: Stop
   - `\di`: Popup **i**nformation (balloon)
   - `\dp`: **P**ause
   - `\dr`: **R**estart
   - `\dx`: Reset *Vimspector*
   - `C-b`: Toggle **b**reakpoint
   - `C-S-b`: Toggle condtional breakpoint
   - `F11`: Step into
   - `S-F11`: Step out
