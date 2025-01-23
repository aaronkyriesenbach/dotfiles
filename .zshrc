source ~/.alias
source ~/.function

export plugins=(alias-finder asdf colored-man-pages docker docker-compose extract git safe-paste)

if command -v autojump &> /dev/null; then
    plugins+=autojump
fi

if command -v kubectl &> /dev/null; then
    plugins+=kubectl
    plugins+=kube-ps1
fi

source $ZSH/oh-my-zsh.sh
