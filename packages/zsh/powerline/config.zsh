# Don't show username for the local user.
DEFAULT_USER=$<USER>

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(status user dir vcs virtualenv
   root_indicator)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(background_jobs load time)

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=false

# No emojis on most Linux installs...
POWERLEVEL9K_PYTHON_ICON="Py"

POWERLEVEL9K_SHORTEN_DIR_LENGTH=4
POWERLEVEL9K_SHORTEN_STRATEGY=truncate_from_right

POWERLEVEL9K_DIR_SHOW_WRITABLE=true

POWERLEVEL9K_HIDE_BRANCH_ICON=true
POWERLEVEL9K_VCS_SHORTEN_LENGTH=16
POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH=16
POWERLEVEL9K_VCS_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_VCS_SHORTEN_DELIMITER=".."

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

