#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

_VENV_PATH="$HOME/python_envs/default"
if [ -d "$_VENV_PATH" ]; then
    rm -rfv "$_VENV_PATH"
fi

export PYTHONNOUSERSITE=1

python3 -m pip install virtualenv
python3 -m virtualenv --clear \
                      --always-copy \
                      --seeder=pip \
                      --download \
                      "$_VENV_PATH"

. "$_VENV_PATH/bin/activate"
pip install \
    pipx \
    ipython \
    jupyterlab \
    numpy \
    pandas \
    matplotlib \
    setuptools
