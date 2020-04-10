#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

sudo snap install pycharm-professional --classic
sudo snap install pycharm-community --classic
sudo snap install code --classic

sudo snap install snap-store
