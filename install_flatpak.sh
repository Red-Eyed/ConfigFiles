#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $(dirname $(readlink -f $0))

sudo flatpak --system remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak --system update --noninteractive

sudo flatpak --system install --noninteractive \
    com.github.tchx84.Flatseal \
    org.mozilla.firefox \
    org.keepassxc.KeePassXC \
    com.slack.Slack \
    com.skype.Client \
    org.telegram \
    com.discordapp.Discord \
    com.github.wwmm.pulseeffects  \
    org.pulseaudio.pavucontrol \
    com.valvesoftware.Steam \
    org.gimp.GIMP \
    org.qbittorrent.qBittorrent \
    org.libreoffice.LibreOffice \
    org.filezillaproject.Filezilla \
    org.videolan.VLC \
    org.gnome.seahorse.Application \
    org.gnome.Logs \
    org.gnome.Maps \
    com.uploadedlobster.peek \
    com.github.unrud.VideoDownloader \
    org.gnome.gedit

mkdir -p $HOME/.config/systemd/user
rsync -a ./linux/flatpak-update.service $HOME/.config/systemd/user/
rsync -a ./linux/flatpak-update.timer $HOME/.config/systemd/user/


systemctl --user enable --now flatpak-update.timer