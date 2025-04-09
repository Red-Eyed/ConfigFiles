#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))

MACHINE=$(uname -m)
INSTALLER=Miniforge3-Linux-$MACHINE.sh
INSTALL_DIR=$HOME/miniforge3

wget -nc https://github.com/conda-forge/miniforge/releases/latest/download/$INSTALLER -P ~/Downloads

chmod +x ~/Downloads/$INSTALLER

if [[ ! -d $INSTALL_DIR/envs/$VENV ]]; then
    ~/Downloads/$INSTALLER -bf
fi

export PATH=$INSTALL_DIR/bin:$PATH

CONDA_EXE=$INSTALL_DIR/bin/conda

source $INSTALL_DIR/bin/activate base

PYTHON_VERSION=3.12
VENV=py-$PYTHON_VERSION

if [[ ! -d $INSTALL_DIR/envs/$VENV ]]; then
    yes | $CONDA_EXE create -n $VENV python=$PYTHON_VERSION
fi

source $INSTALL_DIR/bin/activate $VENV

export PYTHONNOUSERSITE=1
python -m pip install -U pip
