# Envprobe works best if this file is loaded LAST, after all and every other
# setting, alias, extension, etc.

eval "$(~/.local/lib/envprobe/envprobe config hook bash $$)";
