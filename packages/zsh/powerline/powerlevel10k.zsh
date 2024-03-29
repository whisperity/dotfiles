# Don't show username or context for the local user.
DEFAULT_USER="$<USER>"

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
   root_indicator
   midnight_commander
   ranger
   vim_shell
   status
   context
   dir
   vcs
   direnv
   virtualenv

   # Add an explicit newline to render a SPACE (' ') before the user's input.
   newline
)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
   background_jobs
   load
   ram
   command_execution_time
   time
)

POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_PROMPT_ON_NEWLINE=false
POWERLEVEL9K_RPROMPT_ON_NEWLINE=false

POWERLEVEL9K_ICON_PADDING=moderate

POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='%244F\u2502'
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR='%244F\u2502'
POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL='\uE0B2'
POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL='\uE0B4'
POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='\uE0B6'
POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL='\uE0B0'
POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=

POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%244F╭─'
POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%244F├─'
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%244F╰─'
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=
POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX=
POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=

# POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='·'
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='─'
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_BACKGROUND=
POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_GAP_BACKGROUND=
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND='grey50' # 244
POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_FIRST_SEGMENT_END_SYMBOL='%{%}'
POWERLEVEL9K_EMPTY_LINE_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='%{%}'

POWERLEVEL9K_SHORTEN_DIR_LENGTH=4
POWERLEVEL9K_SHORTEN_STRATEGY=truncate_from_right
POWERLEVEL9K_DIR_SHORTENED_FOREGROUND='black'
POWERLEVEL9K_DIR_HYPERLINK=false
POWERLEVEL9K_DIR_SHOW_WRITABLE='v3'
POWERLEVEL9K_DIR_ANCHOR_BOLD=true
local anchor_files=(
 .bzr
 .citc
 .git
 .hg
 .node-version
 .python-version
 .go-version
 .ruby-version
 .lua-version
 .java-version
 .perl-version
 .php-version
 .tool-version
 .shorten_folder_marker
 .svn
 .terraform
 CVS
 Cargo.toml
 composer.json
 go.mod
 package.json
 stack.yaml
)
POWERLEVEL9K_SHORTEN_FOLDER_MARKER="(${(j:|:)anchor_files})"

# These colours are by default set for a dark themed environment.
# FIXME: Create some colour profiles that are appropriate for light background.

POWERLEVEL9K_HIDE_BRANCH_ICON=true
POWERLEVEL9K_VCS_BACKENDS=(git svn)
POWERLEVEL9K_VCS_SHORTEN_LENGTH=16
POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH=16
POWERLEVEL9K_VCS_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_VCS_SHORTEN_DELIMITER="…"

POWERLEVEL9K_DIR_HOME_FOREGROUND='black'
POWERLEVEL9K_DIR_HOME_BACKGROUND='lightskyblue1'
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND='black'
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND='grey100'
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND='black'
POWERLEVEL9K_DIR_DEFAULT_BACKGROUND='thistle1'
POWERLEVEL9K_DIR_ETC_FOREGROUND='darkseagreen1'
POWERLEVEL9K_DIR_ETC_BACKGROUND='hotpink'
POWERLEVEL9K_DIR_NOT_WRITABLE_FOREGROUND='white'
POWERLEVEL9K_DIR_NOT_WRITABLE_BACKGROUND='red3'

POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_BACKGROUND='red'
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND='black'

POWERLEVEL9K_VCS_CLEAN_FOREGROUND='black'
POWERLEVEL9K_VCS_CLEAN_BACKGROUND='120' # lightgreenb
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='black'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='cyan1'
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='deeppink2'
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='darkseagreen1'

POWERLEVEL9K_USER_DEFAULT_FOREGROUND='lightgoldenrod1'
POWERLEVEL9K_USER_DEFAULT_BACKGROUND='black'
POWERLEVEL9K_USER_SUDO_FOREGROUND='orangered1'
POWERLEVEL9K_USER_SUDO_BACKGROUND='black'
POWERLEVEL9K_USER_ROOT_FOREGROUND='purple4'
POWERLEVEL9K_USER_ROOT_BACKGROUND='deepink2'

POWERLEVEL9K_DISABLE_HOT_RELOAD=false

POWERLEVEL9K_TRANSIENT_PROMPT='same-dir'
