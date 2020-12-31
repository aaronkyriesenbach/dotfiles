# Check if macOS (Darwin) or Linux
system_type=$(uname -s)

# Oh-my-ZSH config
export ZSH="$HOME/.oh-my-zsh"
DISABLE_AUTO_UPDATE=true
ZSH_THEME="dracula"

plugins=(
	asdf
	colored-man-pages
	colorize
	command-not-found
	extract
	git
	gradle
)

source $ZSH/oh-my-zsh.sh

# Personal configuration
if [ ! -d "$HOME/.asdf" ]; then
	git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
fi

source ~/.alias
source ~/.function
