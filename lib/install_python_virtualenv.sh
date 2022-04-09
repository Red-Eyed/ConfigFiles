#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

_VENV_PATH="$HOME/python_envs/default"
if [ -x "$(command -v deactivate)" ]; then
    deactivate
fi

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

pipx install -f youtube-dl
pipx install -f speedtest-cli
pipx install -f kaggle
