#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

_VENV_PATH="$HOME/python_envs/default"

export PYTHONNOUSERSITE=0

/usr/bin/python3 -m pip install --user virtualenv pipx
/usr/bin/python3 -m virtualenv  --clear \
                                --always-copy \
                                --seeder=pip \
                                --download \
                                "$_VENV_PATH"

. "$_VENV_PATH/bin/activate"
python3 -m pip install \
    virtualenv \
    pipx \
    ipython \
    jupyterlab \
    numpy \
    pandas \
    matplotlib \
    setuptools

/usr/bin/python3 -m pipx install -f speedtest-cli
/usr/bin/python3 -m pipx install -f kaggle
/usr/bin/python3 -m pipx install -f git-autoshare
