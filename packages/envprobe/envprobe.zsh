# Envprobe works best if this file is loaded LAST, after all and every other
# setting, alias, extension, etc.

unset  ENVPROBE_CONFIG
export ENVPROBE_LOCATION=~/opt/envprobe
export ENVPROBE_SHELL_PID=$$
eval   "$(${ENVPROBE_LOCATION}/envprobe-config.py shell zsh)"
alias  ep='envprobe'
alias  epc='envprobe-config'

