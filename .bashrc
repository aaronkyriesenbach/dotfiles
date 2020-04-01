#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias home='cd ~ && clear'

PS1='[\u@\h \W]\$ '

(cat ~/.cache/wal/sequences &)

export CLARAKM_PARENT=/Users/aaron/dev/teslagov/clarakm

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/aaron/.sdkman"
[[ -s "/home/aaron/.sdkman/bin/sdkman-init.sh" ]] && source "/home/aaron/.sdkman/bin/sdkman-init.sh"
