# Oh-my-ZSH config
export ZSH="$HOME/.oh-my-zsh"
DISABLE_AUTO_UPDATE=true
ZSH_THEME="dracula"

plugins=(
	alias-finder
	asdf
	autojump
	colored-man-pages
	colorize
	command-not-found
	extract
	git
	gradle
	safe-paste
)
 
# Install asdf before sourcing oh-my-zsh.sh so that the asdf plugin can see the cloned dir
if [ ! -d "$HOME/.asdf" ]; then
	git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
fi

source $ZSH/oh-my-zsh.sh

# Personal configuration
source ~/.alias
source ~/.function
