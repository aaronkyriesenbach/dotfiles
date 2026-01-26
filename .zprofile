# Used in scripts to check if macOS (Darwin) or Linux
export SYSTEM_TYPE=$(uname -s)

export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt SHARE_HISTORY

export EDITOR=nvim
export DIFFPROG="nvim -d"
export PYENV_ROOT="$HOME/.pyenv"
export GOPATH="$HOME/.cache/go"

if [ -d ~/.localconfig ]; then
    for file in ~/.localconfig/*; do
	source "$file"
    done
fi

if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export HOMEBREW_NO_ENV_HINTS=true
fi

pathadd=(
    "$HOME/.cargo/bin"
    "$HOME/scripts/path"
    "/usr/share/sway-contrib"
    "$HOME/.krew/bin"
    "$PYENV_ROOT/bin"
    "$HOME/.asdf/shims"
    "$HOME/.yarn/bin"
    "$HOME/.local/bin"
)

for newpath in "${pathadd[@]}"; do
    export PATH="$newpath:$PATH"
done

if [ ! -d ~/.antidote ]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote
fi

export GPG_TTY=$TTY

if command -v sway &> /dev/null && [[ ! ${SSH_TTY} ]]; then
    export _JAVA_AWT_WM_NONREPARENTING=1
    export QT_QPA_PLATFORM=wayland
    export XDG_CURRENT_DESKTOP=sway

    sway
fi
