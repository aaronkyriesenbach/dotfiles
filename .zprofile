# Used in scripts to check if macOS (Darwin) or Linux
export SYSTEM_TYPE=$(uname -s)

export EDITOR=nvim
export DIFFPROG="nvim -d"
export PYENV_ROOT="$HOME/.pyenv"

pathadd=(
    "$HOME/.cargo/bin"
    "$HOME/scripts/path"
    "/usr/share/sway-contrib"
    "$HOME/.krew/bin"
    "$PYENV_ROOT/bin"
    "$HOME/.asdf/shims"
)

for newpath in "${pathadd[@]}"; do
    export PATH="$newpath:$PATH"
done

if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export HOMEBREW_NO_ENV_HINTS=true
fi

export GPG_TTY=$TTY

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

if command -v sway &> /dev/null; then
    export _JAVA_AWT_WM_NONREPARENTING=1
    export QT_QPA_PLATFORM=wayland
    export XDG_CURRENT_DESKTOP=sway

    sway
fi
