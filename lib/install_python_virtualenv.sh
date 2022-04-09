#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

_VENV_PATH="$HOME/python_envs/default"
python3 -m pip install virtualenv
virtualenv --clear \
           --always-copy \
           --seeder=pip \
           --download \
           "$_VENV_PATH"

. "$_VENV_PATH/bin/activate"
python -m pip install
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
