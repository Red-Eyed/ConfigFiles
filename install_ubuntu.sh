#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $(dirname $(readlink -f $0))

sudo apt update
sudo apt install --yes \
    mc \
    vim \
    git \
    zsh \
    htop \
    meld \
    ccache \
    pigz \
    patool \
    build-essential \
    cmake \
    ninja-build \
    g++ \
    clang \
    clang-format \
    lldb \
    neofetch \
    qtcreator \
    earlyoom \
    qbittorrent \
    network-manager-openvpn \
    sqlitebrowser \
    ksystemlog \
    krita \
    openssh-server \
    libreoffice \
    android-tools-adbd \
    gparted \
    seahorse \
    mtp-tools \
    ntfs-3g \
    cifs-utils \
    nfs-common \
    sshfs \
    filezilla \
    flatpak \
    gnome-software-plugin-flatpak \
    gnome-tweaks

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install com.anydesk.Anydesk

# if professional is installed do not install community
if [[ $(snap list | grep -q pycharm) ]]; then
    sudo snap install pycharm-community --classic
fi
sudo snap install code --classic
sudo snap install skype --classic
sudo snap install telegram-desktop
sudo snap install keepassxc


wget -nc https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -P ~/Downloads

chmod +x ~/Downloads/Miniconda3-latest-Linux-x86_64.sh
~/Downloads/Miniconda3-latest-Linux-x86_64.sh -bf

source ~/miniconda3/bin/activate base

pip install --upgrade \
    pip \
    speedtest-cli \
    ipython \
    argcomplete \
    numpy \
    pandas \
    matplotlib

VENV=py37

if [[ ! -d ~/miniconda3/envs/$VENV ]]; then
    yes | conda create -n $VENV python=3.7
fi

source ~/miniconda3/bin/deactivate
source ~/miniconda3/bin/activate $VENV

export PYTHONNOUSERSITE=1



if [[ ! -d $HOME/.oh-my-zsh ]]; then
    git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
else
    cd $HOME/.oh-my-zsh
    git pull
    cd -
fi

rsync -a linux/.bashrc $HOME
rsync -a linux/.zshrc  $HOME
rsync -a linux/.vimrc  $HOME

sudo rsync -r linux/etc/zsh/ /etc/zsh/

if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s $(which zsh)
fi

if [[ -x "$(command -v balooctl)" ]]; then
    balooctl stop
    balooctl disable
fi

echo "###################################"
echo "Please, log out to apply changes!"