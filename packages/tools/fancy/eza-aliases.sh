# Some ls-like aliases for exa (new 'ls')
alias e='eza'
alias el='eza -l'
alias ela='eza -al'
alias elg='eza -al --git'
alias tree='eza --tree'

# Now alias ls-like stuff to 'exa' for real
alias l='e -F'
alias ls='e'
alias la='ela'  # These things are all handled by exa by default
alias ll='el'
alias lh='el'
alias lah='ela'
