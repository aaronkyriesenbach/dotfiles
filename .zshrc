if [ -d $HOME/.alias ]; then
    for f in $HOME/.alias/*; do
	source $f
    done
fi

source $HOME/.antidote/antidote.zsh
antidote load

eval "$(starship init zsh)"
