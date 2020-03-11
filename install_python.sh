wget -nc https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -P ~/Downloads

chmod +x ~/Downloads/Miniconda3-latest-Linux-x86_64.sh

if [[ ! -d ~/miniconda3/envs/$VENV ]]; then
    ~/Downloads/Miniconda3-latest-Linux-x86_64.sh -bf
fi


source ~/miniconda3/bin/activate base
# update conda
yes | conda update -n base -c defaults conda

VENV=py37

if [[ ! -d ~/miniconda3/envs/$VENV ]]; then
    yes | conda create -n $VENV python=3.7
fi

source ~/miniconda3/bin/deactivate
source ~/miniconda3/bin/activate $VENV

export PYTHONNOUSERSITE=1

pip install --upgrade \
    pip \
    speedtest-cli \
    ipython \
    jupyterlab \
    numpy \
    pandas \
    matplotlib \
    setuptools
