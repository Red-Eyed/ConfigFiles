#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $(dirname $(readlink -f $0))

# adding rpm fusion
yes| sudo rpm-ostree install --idempotent --allow-inactive \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm


yes | sudo rpm-ostree --idempotent --allow-inactive \
    file-roller \
    mc \
    vim \
    git \
    zsh \
    htop \
    ccache \
    pigz \
    patool \
    cmake \
    neofetch \
    network-manager-openvpn \
    openssh-server \
    gparted \
    sshfs \
    gnome-tweaks

. ./install_flatpak.sh
. ./install_python.sh
. ./install_oh-my-zsh.sh

echo "###################################"
echo "Please, log out to apply changes!"
