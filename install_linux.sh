#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $(dirname $(readlink -f $0))
export ROOT_DIR=$PWD

if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
    /bin/gsettings set org.gnome.shell.app-switcher current-workspace-only true
    /bin/gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true
fi

pkg_managers="pacman apt rpm-ostree"

for cmd in $pkg_managers; do
    if [ x$(command -v $cmd) != x ]; then
        ./lib/install_$cmd.sh
        break
    fi
done

# Enable fstrim for SSD
sudo systemctl enable fstrim.timer

# dotfiles should be first
./lib/install_dotfiles.sh

./lib/install_snap.sh
./lib/install_python.sh
./lib/install_oh-my-zsh.sh

echo "###################################"
echo "Please, log out to apply changes!"
