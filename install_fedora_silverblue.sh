#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $(dirname $(readlink -f $0))

pkgs="\
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpmfile-roller \
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
    gnome-tweaksfuse-sshfs \
    strace \
    tmux \
"

status=$(rpm-ostree status)
for pkg in $pkgs; do
    pkg=$(basename "$pkg")
    if ! grep -qF "$pkg" <<< "${status}"; then
        rpm-ostree install $pkgs
        break
    fi
done

. ./install_flatpak.sh
. ./install_python.sh
. ./install_oh-my-zsh.sh

echo "###################################"
echo "Please, log out to apply changes!"
