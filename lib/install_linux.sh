#!/bin/bash
set -e

cd $ROOT_DIR

for sh in `find -L $ROOT_DIR -name "*.sh"`;do
    chmod +x $sh
done

if [[ $ARGS_MODE  == "gui" ]]; then
    if [[ "$XDG_CURRENT_DESKTOP" =~ "GNOME" ]]; then
        /bin/gsettings set org.gnome.shell.app-switcher current-workspace-only true || true
        /bin/gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true || true
    fi
fi

./lib/install_system_pkgs.sh $ARGS_MODE

if [[ $ARGS_CONFIGURE_SYSTEMD == "yes" ]]; then
    if [ systemctl ]; then
        ./lib/configure_systemd.sh
    fi
fi

# Make vim as default
if command -v update-alternatives > /dev/null ; then
    sudo update-alternatives --set editor /usr/bin/vim.basic
fi

# dotfiles should be the first
./lib/install_dotfiles.sh

if [[ $ARGS_INSTALL_SNAP == "yes" ]]; then
    if [ systemctl ]; then
        ./lib/install_snap.sh
    fi
fi

./lib/install_python_virtualenv.sh
./lib/install_oh-my-zsh.sh

neofetch

echo "###################################"
echo "Installation successfully completed."
echo "Please, log out to apply changes!"
