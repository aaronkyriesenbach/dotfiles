#!/bin/bash

sudo pacman -S sway swaylock swayidle swaybg waybar sway-contrib git iwd ttf-iosevka-nerd ttf-liberation sudo base-devel less fd mako vim neovim brightnessctl


git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

paru -S avizo
