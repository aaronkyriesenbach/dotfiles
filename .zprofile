export _JAVA_AWT_WM_NONREPARENTING=1
export KITTY_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1

export EDITOR=nvim
export DIFFPROG="nvim -d"

# Used in scripts to check if macOS (Darwin) or Linux
export SYSTEM_TYPE=$(uname -s)

[ -d $HOME/scripts ] && export PATH="$HOME/scripts:$PATH"

[ -f $HOME/.secret ] && source $HOME/.secret
