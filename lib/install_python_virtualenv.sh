#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

_VENV_PATH="$HOME/python_envs/default"


/usr/bin/python3 -m pip install virtualenv
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
