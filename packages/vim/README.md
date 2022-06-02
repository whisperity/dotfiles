`vim` configuration, keybinds
=============================

> :warning: **Caution!** Some of the plugins installed might *NOT* work with pure Vim, only with [neovim](http://neovim.io).

Starting Vim
------------

 * `darkvim` (default)
 * `lightvim`

Keybinds
--------

### Navigation

| Key       | Action                                      | Comments            |
|:---------:|:--------------------------------------------|:--------------------|
| `-`       | Jump to split/window visually               |                     |
| `F2`      | Select buffer                               |                     |
| `F3`/`F4` | Go to previous/next buffer                  |                     |
| `,tc`     | **T**ab **c**lose                           |                     |
| `,tt`     | **T**ab selector                            |                     |
| `,ff`     | **F**uzzy find **f**ile contents            |                     |
| `,fm`     | **F**uzzy find **m**arks                    |                     |
| `C-f`     | Fuzzy find in current **f**ile              | mirrors Zsh keybind |
| `C-g`     | Fuzzy find **G**it versioned files          | mirrors Zsh keybind |
| `C-n`     | Toggle file **n**avigator (explorer)        |                     |
| `C-t`     | Fuzzy find in file **t**ree                 | mirrors Zsh keybind |
| `C-x`     | Close buffer                                |                     |
| `C-c C-x` | Close old buffers, e.g. files in background |                     |
| `q:`      | Command history                             |                     |

### Vim _c_onfiguration (`C-c`)


| Key       | Action                                                                       | Comments                                                  |
|:---------:|:-----------------------------------------------------------------------------|:----------------------------------------------------------|
| `C-c C-c` | Exit _Terminal_ mode and return to Normal                                    | Neovim-only!                                              |
| `C-c C-f` | Toggle **f**olding                                                           |                                                           |
| `C-c C-g` | Toggle **G**oyo mode - centred total focus                                   | [goyo.vim](http://github.com/junegunn/goyo.vim)           |
| `C-c C-l` | Toggle **l**imelight - darken out everything except currently edited context | [limelight.vim](http://github.com/junegunn/limelight.vim) |
| `C-c C-p` | Toggle **p**aste-mode                                                        |                                                           |
| `C-c C-r` | Toggle **r**ainbow highlight of brackets                                     |                                                           |
| `C-c C-u` | Toggle **u**ndo history                                                      |                                                           |
| `C-c C-v` | Toggle **v**isual location (crosshair)                                       |                                                           |
| `C-c C-y` | Toggle conceal                                                               |                                                           |

### Generic things

| Key       | Action                                       | Comments                                                 |
|:---------:|:---------------------------------------------|:---------------------------------------------------------|
| `<Space>` | Apply recorded **macro** in register **`q`** | **Normal** mode. The macro recording is started by `qq`. |
| `C-]`     | Unhighlight search results                   |                                                          |


### Version control ([fugitive](http://github.com/tpope/vim-fugitive)): `<LocalLeader>g`

| Key   | Action                                          | Comments |
|:-----:|:------------------------------------------------|:---------|
| `,gg` | Show the Fugitive status and management window  |          |
| `,gb` | Show the `git blame` view of the current buffer |          |
| `,gm` | Show the commit which changed the current line  |          |

### Programming

| Key   | Action                                    | Comments |
|:-----:|:------------------------------------------|:---------|
| `gc`  | Toggle **c**ommenting of selection        |          |
| `gcc` | Toggle **c**ommenting of **c**urrent line |          |

#### Markdown

| Key   | Action                              | Comments |
|:-----:|:------------------------------------|:---------|
| `C-f` | Format the *table* under the cursor |          |

#### Code completion ([coc.nvim](http://github.com/neoclide/coc.nvim)): `<LocalLeader>y`

| Key   | Action                                                   | Comments    |
|:-----:|:---------------------------------------------------------|:------------|
| `,ya` | **A**pply suggested actions                              |             |
| `,yc` | Documentation for **c**ode under cursor                  |             |
| `,yd` | Jump to **d**efinition                                   |             |
| `,ye` | Show **e**rrors                                          |             |
| `,yf` | Symbol **f**inder                                        |             |
| `,yF` | **F**ormat file, or selected code                        |             |
| `,yh` | Swutch between **h**eader and source file                | C/C++-only! |
| `,yH` | Switch between **h**eader and source file _in new split_ | C/C++-only! |
| `,yi` | System **i**nformation                                   |             |
| `,yn` | **N**ext diagnostic                                      |             |
| `,yp` | **P**revious diagnostic                                  |             |
| `,yr` | Show **r**eferences                                      |             |
| `,ys` | Rename **s**ymbol                                        |             |
| `,yt` | Browse symbol **t**ree (tags)                            |             |
| `,yx` | Fi**x** current diagnostic                               |             |
| `,yy` | Restart server                                           |             |

#### Debugging ([vimspector](http://github.com/puremourning/vimspector)): `<LocalLeader>d`

| Key     | Action                              | Comments     |
|:-------:|:------------------------------------|:-------------|
| `F5`    | Start or continue debugging         |              |
| `,dS`   | **S**top debugger                   |              |
| `C-F5`  | Stop debugger                       | Neovim-only! |
| `F11`   | Step into                           |              |
| `,dso`  | **S**tep **o**ut                    |              |
| `F10`   | Step out                            |              |
| `C-F11` | Step out                            | Neovim-only! |
| `,dsr`  | **S**tep ove**r**                   |              |
| `S-F11` | Step over                           | Neovim-only! |
| `,db`   | Toggle **b**reakpoint               |              |
| `,dB`   | Toggle _conditional_ **b**reakpoint |              |
| `,di`   | **I**nspect expression              |              |
| `,dj`   | Move _down_ the stack               |              |
| `,dk`   | Move _up_ the stack                 |              |
| `,dp`   | **P**ause debugger                  |              |
| `,dr`   | **R**estart debugger                |              |
| `,dx`   | E**x**it Vimspector                 |              |

### LaTeX ([vimtex](http://github.com/lervag/vimtex)): `<LocalLeader>l`

| Key   | Action                                         | Comments |
|:-----:|:-----------------------------------------------|:---------|
| `,le` | Show **e**rrors                                |          |
| `,li` | System **i**nformation                         |          |
| `,ll` | Compi**l**e document and open viewer           |          |
| `,lt` | Browse **t**ags (document layout)              |          |
| `,lv` | **V**iew document                              |          |
| `C-l` | Turn **L**aTeX sequence into Unicode character |          |
