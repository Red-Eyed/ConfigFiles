sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak update --noninteractive
sudo flatpak install --noninteractive \
    com.github.tchx84.Flatseal \
    org.keepassxc.KeePassXC \
    com.slack.Slack \
    com.skype.Client \
    org.telegram
