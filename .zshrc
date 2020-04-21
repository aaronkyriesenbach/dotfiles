# Oh-My-Zsh configuration

# Path to your oh-my-zsh installation.
export ZSH="/home/aaron/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnostercustom"

HYPHEN_INSENSITIVE="true"

DISABLE_AUTO_UPDATE="true"

DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# Personal configuration

source ~/.alias

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/aaron/.sdkman"
[[ -s "/home/aaron/.sdkman/bin/sdkman-init.sh" ]] && source "/home/aaron/.sdkman/bin/sdkman-init.sh"
