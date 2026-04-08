#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

systemctl-exists() {
    local count
    count=$(systemctl list-unit-files "${1}*" | wc -l)
    [ "$count" -gt 3 ]
}

# Fix systemd-resolvd
sudo systemctl enable systemd-resolved --now
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Enable fstrim for SSD
sudo systemctl enable fstrim.timer --now

for unit in ./systemd_units/*; do
    sudo cp "$unit" /etc/systemd/system/
    sudo systemctl enable "$(basename "$unit")" --now
done
