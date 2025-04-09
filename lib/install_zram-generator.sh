
# installing systemd-zram-generator
# https://github.com/systemd/zram-generator

cd /tmp

ZRAM_GENERATOR_DIR=/tmp/zram-generator

if [[ ! -d $ZRAM_GENERATOR_DIR ]]; then
    git clone https://github.com/systemd/zram-generator
fi


# install latest rust
# https://github.com/rust-lang-deprecated/rustup.sh/issues/83#issuecomment-297613830
curl https://sh.rustup.rs -sSf | sh -s -- -y
export PATH=$HOME/.cargo/bin:$PATH

sudo apt-get install --no-install-recommends ronn --yes


cd $ZRAM_GENERATOR_DIR
make build
sudo make install NOBUILD=true

sudo systemctl daemon-reload
sudo systemctl enable /dev/zram0 --now