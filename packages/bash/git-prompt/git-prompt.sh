# Use the Git Bash extension.
GIT_PROMPT_ONLY_IN_REPO=1
GIT_PROMPT_FETCH_REMOTE_STATUS=0
GIT_PROMPT_SHOW_UPSTREAM=0
GIT_PROMPT_SHOW_UNTRACKED_FILES=no
GIT_PROMPT_THEME=Default_Ubuntu

if [ -z "$no_git_prompt" ]; then
  source ~/.bash.d/git-prompt/gitprompt.sh
fi
