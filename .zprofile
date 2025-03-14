# Used in scripts to check if macOS (Darwin) or Linux
export SYSTEM_TYPE=$(uname -s)

export EDITOR=nvim
export DIFFPROG="nvim -d"

[ -d $HOME/.cargo/bin ] && export PATH="$HOME/.cargo/bin:$PATH"

[ -d $HOME/scripts/path ] && export PATH="$HOME/scripts/path:$PATH"

if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export HOMEBREW_NO_ENV_HINTS=true
fi

[ -d /opt/homebrew/opt/python ] && export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"
[ -d /usr/share/sway-contrib ] && export PATH="/usr/share/sway-contrib:$PATH"

export ZSH="$HOME/.oh-my-zsh"

if [ ! -d "$ZSH" ]; then
    echo "Installing Oh My ZSH"
    git clone -b master https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
fi

if [ ! -f "$ZSH/themes/dracula.zsh-theme" ]; then
    echo "Installing ZSH Dracula theme"
    ZSH_DRACULA="/tmp/zsh-dracula"

    git clone https://github.com/dracula/zsh.git "$ZSH_DRACULA"
    mv "$ZSH_DRACULA/dracula.zsh-theme" "$ZSH/themes/"
    mv "$ZSH_DRACULA/lib" "$ZSH/themes/"
fi

export ZSH_THEME="dracula"

export GPG_TTY=$TTY

if [[ $SYSTEM_TYPE != "Darwin" ]] && ! grep -q microsoft /proc/version && command -v sway &> /dev/null; then
    export _JAVA_AWT_WM_NONREPARENTING=1
    export QT_QPA_PLATFORM=wayland
    export XDG_CURRENT_DESKTOP=sway

    sway
fi
