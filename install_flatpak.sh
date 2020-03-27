sudo flatpak --system remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak --system update --noninteractive

sudo flatpak --system install --noninteractive \
    com.github.tchx84.Flatseal \
    org.keepassxc.KeePassXC \
    com.slack.Slack \
    com.skype.Client \
    org.telegram \
    com.discordapp.Discord \
    com.github.wwmm.pulseeffects  \
    com.valvesoftware.Steam \
    org.gimp.GIMP \
    org.qbittorrent.qBittorrent \
    org.libreoffice.LibreOffice \
    org.gnome.seahorse.Application \
    org.filezillaproject.Filezilla \
    org.videolan.VLC \
    org.gnome.Logs \
    org.gnome.Maps
