#!/bin/bash

sudo apt update
sudo apt upgrade
sudo apt install virtualbox-guest-utils
sudo apt install git

cd $HOME/.ssh
if [ ! -f id_ed25519 ]; then
    ssh-keygen -t ed25519
    echo "New public ssh key $(cat ed25519.pub)"
fi

git clone git@github.com:jctaylor/dotfiles.git || echo "Maybe this is private again. Upload public ssh key"; exit 1

# curl and build-essentials
sudo apt install curl build-essential -y

# clang  (1GB disk space)
sudo apt install clang-20 clang-format-20 clang-tidy-20 clang-tools-20 clangd-20 -y

# Lua Rocks (need version 5.1)

apt install luarocks build-essential libreadline-dev lua5.4
sudo apt install lua5.1 lua5.1-doc liblua5.1-dev
luarocks --local --lua-version 5.1 install jsregexp
luarocks --local --lua-version 5.1 install jsregexp
# apt install liblua5.4-dev
# sudo apt install liblua5.3-dev -y
wget https://luarocks.org/releases/luarocks-3.13.0.tar.gz
tar zxpf luarocks-3.13.0.tar.gz
cd luarocks-3.13.0
./configure && make && sudo make install
sudo luarocks install luasocket

# python
sudo apt install pipx
pipx install pynvim
pipx install python-lsp-server

# Rust (see rustup.rs)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Ruby
sudo apt-get install ruby-full  # Does this install ruby-dev?
sudo gem install neovim

# ripgrep
sudo apt update
sudo apt install ripgrep -y

# node.js
sudo apt update
sudo apt install curl -y
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
nvm install --lts  # Uses nvm to install latest long term support version

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
# nvim (Ubuntu is notoriously behind in versions)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
cd ~/.local
mkdir bin
tar -xzf ../nvim-linux-x86_64.tar.gz
mv nvim-linux-x86_64 nvim
cd bin
ln -s ../nvim/bin/nvim .
echo 'PATH=${HOME}/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc    # This is temporary until dotfiles updates .bashrc



## nvim recommended:

    * ripgrep
    * node.js
    * Ingore perl provider
    * ruby
    * gem
