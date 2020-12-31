# Check if macOS (Darwin) or Linux
system_type=$(uname -s)

# Oh-my-ZSH config
export ZSH="$HOME/.oh-my-zsh"
DISABLE_AUTO_UPDATE=true
ZSH_THEME="dracula"

plugins=(
	colored-man-pages
	colorize
	command-not-found
	extract
	git
	gradle
)

source $ZSH/oh-my-zsh.sh

# Personal configuration
source "$HOME/.sdkman/bin/sdkman-init.sh" 2> /dev/null

source ~/.alias
source ~/.function
