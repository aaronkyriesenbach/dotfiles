# Check if macOS (Darwin) or Linux
system_type=$(uname -s)

# Oh-my-ZSH config
export ZSH="$HOME/.oh-my-zsh"
DISABLED_AUTO_UPDATE=true
ZSH_THEME="dracula"

if [ "$system_type" = "Darwin" ]; then
	plugins=(git)
else
	plugins=(git archlinux)
fi

source $ZSH/oh-my-zsh.sh

# Personal configuration
if [ "$system_type" = "Darwin" ]; then
	source $HOME/.nvm/nvm.sh 2> /dev/null
else
	source "/usr/share/nvm/init-nvm.sh" 2> /dev/null
fi

source "$HOME/.sdkman/bin/sdkman-init.sh" 2> /dev/null

source ~/.alias
source ~/.function
