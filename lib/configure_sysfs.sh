cd $(dirname $(readlink -f $0))

sudo cp -r sysfs.d /etc/
sudo systemctl enable sysfsutils --now
sudo systemctl restart sysfsutils
