if [ -d $HOME/.alias ]; then
    for f in $HOME/.alias/*; do
	source $f
    done
fi

source $HOME/.antidote/antidote.zsh
antidote load

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

precmd() { precmd() { echo } }
eval "$(starship init zsh)"
