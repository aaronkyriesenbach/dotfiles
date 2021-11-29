export _JAVA_AWT_WM_NONREPARENTING=1
export KITTY_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=gtk2
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1
export LIBSEAT_BACKEND=logind

export TERM=xterm-kitty
export EDITOR=nvim
export DIFFPROG="nvim -d"

# Used in scripts to check if macOS (Darwin) or Linux
export SYSTEM_TYPE=$(uname -s)

[ -d $HOME/.cargo/bin ] && export PATH="$HOME/.cargo/bin:$PATH"

[ -d $HOME/scripts/path ] && export PATH="$HOME/scripts/path:$PATH"

[ -f $HOME/.secret ] && source $HOME/.secret
