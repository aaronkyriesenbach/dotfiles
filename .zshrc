source ~/.alias
source ~/.function

export plugins=(alias-finder colored-man-pages docker docker-compose extract git safe-paste)

if command -v asdf &> /dev/null; then
    plugins+=asdf
fi

if command -v autojump &> /dev/null; then
    plugins+=autojump
fi

if command -v kubectl &> /dev/null; then
    plugins+=kubectl
    plugins+=kube-ps1

    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
fi

zstyle ':omz:update' mode auto # Allow OMZ to auto update

source $ZSH/oh-my-zsh.sh

if command -v kube_ps1 &> /dev/null; then
    export PROMPT='$(kube_ps1)'$PROMPT
fi

if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - zsh)"
fi
