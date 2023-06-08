#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

MACHINE=$(uname -m)
MINICONDA3=Miniconda3-latest-Linux-${MACHINE}.sh

wget -nc https://repo.continuum.io/miniconda/$MINICONDA3 -P ~/Downloads

chmod +x ~/Downloads/$MINICONDA3

# fix for conda that relies on libffi v6
# sudo ln -sf /usr/lib/${MACHINE}-linux-gnu/libffi.so /usr/lib/${MACHINE}-linux-gnu/libffi.so.6

if [[ ! -d ~/miniconda3/envs/$VENV ]]; then
    ~/Downloads/$MINICONDA3 -bf
fi

source ~/miniconda3/bin/activate base
# update conda
yes | conda update -n base -c defaults conda

VENV=py39
PYTON_VERSION=3.9

if [[ ! -d ~/miniconda3/envs/$VENV ]]; then
    yes | conda create -n $VENV python=$PYTON_VERSION
fi

conda deactivate
source ~/miniconda3/bin/activate $VENV

export PYTHONNOUSERSITE=1
python -m pip install -U pip
