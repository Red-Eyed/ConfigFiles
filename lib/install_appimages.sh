#!/bin/bash

mkdir -p ~/appimages
cd ~/appimages

packages="
https://github.com/nelsonenzo/tmux-appimage/releases/download/3.2a/tmux.appimage
https://github.com/Syllo/nvtop/releases/download/3.0.2/nvtop-x86_64.AppImage
"

for pkg in $packages;
do
    wget $pkg
done

chmod +x ./*