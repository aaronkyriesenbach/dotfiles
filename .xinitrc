eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK
[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources
udiskie &
wal -R
exec startplasma-x11
