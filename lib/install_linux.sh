#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $ROOT_DIR

for sh in `find -L $ROOT_DIR -name "*.sh"`;do
    chmod +x $sh
done


if [[ "$XDG_CURRENT_DESKTOP" =~ "GNOME" ]]; then
    /bin/gsettings set org.gnome.shell.app-switcher current-workspace-only true || true
    /bin/gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true || true
fi

./lib/install_system_pkgs.sh $ARGS_MODE

if [ ! systemctl ]; then
    ./lib/configure_systemd.sh
fi

# Make vim as default
if command -v update-alternatives > /dev/null ; then
    sudo update-alternatives --set editor /usr/bin/vim.basic
fi

# dotfiles should be the first
./lib/install_dotfiles.sh

./lib/install_snap.sh
./lib/install_python.sh
./lib/install_oh-my-zsh.sh

neofetch

echo "###################################"
echo "Installation successfully completed."
echo "Please, log out to apply changes!"