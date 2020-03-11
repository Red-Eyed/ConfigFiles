# if professional is installed do not install community
if [[ $(snap list | grep -q pycharm-professional) ]] ; then
    sudo snap install pycharm-community --classic
fi

sudo snap install code --classic
sudo snap install skype --classic
sudo snap install telegram-desktop
sudo snap install keepassxc
