`vim` configuration, keybinds
=============================

> :warning: **Caution!** Some of the plugins installed might *NOT* work with pure Vim, only with [neovim](http://neovim.io).

Starting Vim
------------

 * `darkvim` (default)
 * `lightvim`

Keybinds
--------

 * Navigation
   - `-`: Jump to split/window based on next letter
   - `F2`: Buffer list
   - `F3`/`F4`: Previous/next buffer
   - `,tc`: **T**ab **c**lose
   - `,tt`: Window/Tab switcher
   - `,ff`: **F**uzzy **f**ind file contents
   - `,fm`: **F**uzzy find **m**arks
   - `C-f`: Fuzzy **f**ind in current file
   - `C-g`: Fuzzy find **G**it versioned files
   - `C-n`: Toggle file explorer
   - `C-t`: Fuzzy find filenames
   - `C-x`: Close buffer
   - `q:`: Command history
 * Vim configuration (`C-c`)
   - `C-c C-c`: Exit Terminal back to vim (NeoVim only)
   - `C-c C-f`: Toggle **f**olding
   - `C-c C-p`: Toggle **p**aste mode
   - `C-c C-r`: Toggle **r**ainbow-brackets
   - `C-c C-u`: **U**ndo-history
   - `C-c C-y`: Toggle conceal
 * **Normal** `Space`: Apply the contents of the **macro** in register **`q`** (the macro recording started by `qq`).
 * Programming
   - `gc`: Toggle **c**omments for selection
   - `gcc`: Toggle **c**omments for **c**urrent line
 * C/C++
   - **Selection** `C-f`: `clang-format` selected text
 * [coc.nvim](http://github.com/neoclide/coc.nvim) (formerly **Y**ouCompleteMe): `<LocalLeader>y`
   - `,ya`: **A**pply suggested actions
   - `,yc`: Documentation for **c**ode
   - `,yd`: Jump to **d**efinition
   - `,ye`: Show **e**rrors
   - `,yf`: Symbol **f**inder
   - `,yh`: Switch between **h**eader and source file (C++-only!)
   - `,yi`: System **i**nformation
   - `,yn`: **N**ext diagnostic
   - `,yp`: **P**revious diagnostic
   - `,yr`: Show **r**eferences
   - `,ys`: Rename **s**ymbol
   - `,yt`: Browse **t**ags (symbol browser)
   - `,yx`: Fi**x** current diagnostic
   - `,yy`: Restart server
 * [vimTeX](http://github.com/lervag/vimtex/): `<LocalLeader>l`
   - `,le`: Show **e**rrors
   - `,li`: System **i**nformation
   - `,ll`: Compi**l**e and view
   - `,lt`: Browse **t**ags (document layout)
   - `,lv`: **V**iew
   - `C-l`: Unicodify LaTeX sequence
 * [Vimspector](http://github.com/puremourning/vimspector): `<LocalLeader>d` - **d**ebugger
   - `F5`: Continue
   - `C-F5`: Stop
   - `F11`: Step into
   - `S-F11`: Step out
   - `,di`: Popup **i**nformation (balloon)
   - `,dp`: **P**ause
   - `,dr`: **R**estart
   - `,dx`: Reset *Vimspector*
   - `C-b`: Toggle **b**reakpoint
   - `C-S-b`: Toggle condtional breakpoint
