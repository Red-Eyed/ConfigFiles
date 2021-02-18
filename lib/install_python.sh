#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

wget -nc https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -P ~/Downloads

chmod +x ~/Downloads/Miniconda3-latest-Linux-x86_64.sh

# fix for conda that relies on libffi v6
sudo ln -sf /usr/lib/x86_64-linux-gnu/libffi.so /usr/lib/x86_64-linux-gnu/libffi.so.6

if [[ ! -d ~/miniconda3/envs/$VENV ]]; then
    ~/Downloads/Miniconda3-latest-Linux-x86_64.sh -bf
fi

source ~/miniconda3/bin/activate base
# update conda
yes | conda update -n base -c defaults conda

VENV=py38
PYTON_VERSION=3.8

if [[ ! -d ~/miniconda3/envs/$VENV ]]; then
    yes | conda create -n $VENV python=$PYTON_VERSION
fi

conda deactivate
source ~/miniconda3/bin/activate $VENV

export PYTHONNOUSERSITE=1
python -m pip install -U pip

python -m pip install --upgrade \
    pipx \
    ipython \
    jupyterlab \
    numpy \
    pandas \
    matplotlib \
    setuptools

pipx install -f youtube-dl
pipx install -f speedtest-cli
pipx install -f kaggle
