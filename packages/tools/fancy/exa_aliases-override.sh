# Some ls-like aliases for exa (new 'ls')
alias e='exa'
alias el='exa -al'
alias elg='exa -al --git'
alias tree='exa --tree'

# Now alias ls-like stuff to 'exa' for real
alias l='e -F'
alias ls='e'
alias la='el' # These things are all handled by exa by default
alias lh='el'

