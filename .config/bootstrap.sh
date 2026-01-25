#!/bin/bash

sudo pacman -S sway swaylock swayidle swaybg waybar sway-contrib git iwd ttf-iosevka-nerd ttf-liberation sudo base-devel less fd mako vim neovim brightnessctl direnv kubectl starship foot unzip wget


git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

paru -S avizo sway-launcher-desktop asdf-vm
