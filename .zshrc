# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+r:|[._-]=* r:|=*'
zstyle :compinstall filename '/home/aaron/.zshrc'

autoload -Uz compinit
compinit

autoload -Uz promptinit
promptinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=10000
setopt autocd beep extendedglob notify
unsetopt nomatch
bindkey -v
# End of lines configured by zsh-newuser-install
[[ $- != *i* ]] && return

PROMPT='%n@%M %1d$ '
(cat ~/.cache/wal/sequences &)

source ~/.alias

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/aaron/.sdkman"
[[ -s "/home/aaron/.sdkman/bin/sdkman-init.sh" ]] && source "/home/aaron/.sdkman/bin/sdkman-init.sh"
