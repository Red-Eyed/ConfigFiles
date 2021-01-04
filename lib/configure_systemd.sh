#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

systemctl-exists() {
  [ $(systemctl list-unit-files "${1}*" | wc -l) -gt 3 ]
}

if systemctl-exists avahi-daemon.service ; then
    sudo systemctl disable avahi-daemon.service --now
fi

# Fix systemd-resolvd SSD
sudo systemctl enable systemd-resolved --now
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Enable fstrim for SSD
sudo systemctl enable fstrim.timer --now

for unit in $(ls -1 ./systemd_units/); do
    sudo cp ./systemd_units/$unit /etc/systemd/system/
    sudo systemctl enable $(basename $unit) --now
done
