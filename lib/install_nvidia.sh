#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

#
# Follovied by the tutorial: https://download.nvidia.com/XFree86/Linux-x86_64/450.57/README/powermanagement.html
#
NVIDIA_DRIVER_VERSION=$(head -1 /proc/driver/nvidia/version | sed "s/.*Kernel Module *\([0-9]*\)\. *.*/\1/g")
NVIDIA_DIR=/usr/share/doc/nvidia-driver-${NVIDIA_DRIVER_VERSION}

if [[ ! -d ${NVIDIA_DIR} ]]; then
    echo ${NVIDIA_DIR} does not exist. Skipping.
    exit 0
fi

# Installing
sudo install ${NVIDIA_DIR}/nvidia-suspend.service   /etc/systemd/system
sudo install ${NVIDIA_DIR}/nvidia-hibernate.service /etc/systemd/system
sudo install ${NVIDIA_DIR}/nvidia-resume.service    /etc/systemd/system
sudo install ${NVIDIA_DIR}/nvidia                   /lib/systemd/system-sleep
sudo install ${NVIDIA_DIR}/nvidia-sleep.sh          /usr/bin

# Enabling nvidia systemd
sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-hibernate.service
sudo systemctl enable nvidia-resume.service
