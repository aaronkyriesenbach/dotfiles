[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources
udiskie &
wal -R
exec i3
