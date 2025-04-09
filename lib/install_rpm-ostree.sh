#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

# adding rpm fusion
yes | sudo rpm-ostree install --idempotent --allow-inactive \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

yes | sudo rpm-ostree upgrade

yes | sudo rpm-ostree install --idempotent --allow-inactive \
    file-roller \
    unrar \
    p7zip \
    mc \
    vim \
    git \
    zsh \
    htop \
    ccache \
    pigz \
    cmake \
    neofetch \
    openssh-server \
    gparted \
    sshfs \
    gnome-tweaks \
    nmap \
    nautilus-python \
    nautilus-extensions \
    openssl \
    stow
