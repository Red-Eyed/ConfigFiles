#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $(dirname $(readlink -f $0))

if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
    /bin/gsettings set org.gnome.shell.app-switcher current-workspace-only true
    /bin/gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true
fi

# Enable fstrim for SSD
sudo systemctl enable fstrim.timer

sudo pacman -Suy --needed --noconfirm \
    base-devel \
    gcc-fortran \
    intel-tbb \
    cblas \
    lapack \
    lapacke \
    eigen \
    strace \
    yay \
    mc \
    vim \
    git \
    git-lfs \
    zsh \
    htop \
    meld \
    ccache \
    pigz \
    cmake \
    ninja \
    clang \
    lldb \
    fwupd \
    ethtool \
    neofetch \
    vlc \
    qtcreator \
    sqlitebrowser \
    android-tools \
    gparted \
    grub-customizer \
    ntfs-3g \
    cifs-utils \
    sshfs \
    openssh \
    filezilla \
    snapd \
    flatpak \
    gtkhash-nautilus \
    hardinfo \
    tlpui \
    gnome-software

sudo systemctl enable --now snapd.socket
sudo ln -sf /var/lib/snapd/snap /snap

. ./install_flatpak.sh
. ./install_snap.sh
. ./install_python.sh
. ./install_oh-my-zsh.sh

if [[ -x "$(command -v balooctl)" ]]; then
    balooctl stop
    balooctl disable
fi

echo "###################################"
echo "Please, log out to apply changes!"
