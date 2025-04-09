#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

_VENV_PATH="$HOME/python_envs/default"
export PYTHONNOUSERSITE=0

python3 -m venv $_VENV_PATH --copies --clear --upgrade-deps
. $_VENV_PATH/bin/activate

python3 -m pip install virtualenv pipx
python3 -m pip install \
    pipx \
    ipython \
    jupyterlab \
    numpy \
    pandas \
    matplotlib \
    setuptools
