#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $(dirname $(readlink -f $0))

sudo snap install pycharm-professional --classic
sudo snap install pycharm-community --classic
sudo snap install code --classic

sudo snap install snap-store
