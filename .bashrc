#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias home='cd ~ && clear'

PS1='[\u@\h \W]\$ '
