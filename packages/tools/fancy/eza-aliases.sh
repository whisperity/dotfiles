# Some ls-like aliases for eza (new 'ls')
alias e='eza'
alias el='eza -lb'
alias ela='eza -alb'
alias elg='eza -alb --git'
alias tree='eza --tree'

# Now alias ls-like stuff to 'eza' for real.
alias l='e -F'
alias ls='e'
# These things are all handled by eza by default.
alias la='ela'
alias ll='el'
alias lh='el'
alias lah='ela'
