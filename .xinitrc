[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources
wal -R
exec i3
