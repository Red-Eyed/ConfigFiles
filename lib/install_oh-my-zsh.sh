set -e
cd $(dirname $(readlink -f $0))
. header.sh

if [[ -d !~/.oh-my-zsh ]]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
fi
