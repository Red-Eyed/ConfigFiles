cd $(dirname $(readlink -f $0))

# https://wiki.debian.org/ZRam

sudo cp -r etc/default/zramswap /etc/default/zramswap

sudo systemctl enable zramswap --now
sudo systemctl zramswap reload
