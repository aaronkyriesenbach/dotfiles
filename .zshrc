# Oh-my-ZSH config
export ZSH="$HOME/.oh-my-zsh"

if [ ! -d "$ZSH" ]; then
    git clone -b master https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
fi

# Dracula theme install
if [ ! -f "$ZSH/themes/dracula.zsh-theme" ]; then
    ZSH_DRACULA="/tmp/zsh-dracula"

    git clone https://github.com/dracula/zsh.git "$ZSH_DRACULA"
    mv "$ZSH_DRACULA/dracula.zsh-theme" "$ZSH/themes/"
    mv "$ZSH_DRACULA/lib" "$ZSH/themes/"
fi

DISABLE_AUTO_UPDATE=true
ZSH_THEME="dracula"

plugins=(
    alias-finder
    asdf
    colored-man-pages
    colorize
    command-not-found
    docker
    docker-compose
    extract
    git
    gradle
    safe-paste
)

if command -v autojump &> /dev/null; then
    plugins+=autojump
fi

if command -v kubectl &> /dev/null; then
    plugins+=kubectl
    plugins+=kube-ps1
fi
 
# Install asdf before sourcing oh-my-zsh.sh so that the asdf plugin can see the cloned dir
if [ ! -d "$HOME/.asdf" ]; then
    git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
fi

source $ZSH/oh-my-zsh.sh

PROMPT='$(kube_ps1)'$PROMPT

# Personal configuration
source ~/.alias
source ~/.function

export GPG_TTY=$TTY
