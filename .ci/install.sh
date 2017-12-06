#!/usr/bin/env bash

# Fail on unset variables and command errors
set -ue -o pipefail

# Prevent commands misbehaving due to locale differences
export LC_ALL=C

# Get root path of the script
root=$(cd $(dirname $0); pwd)

# Load OS specific script
. $root/install/${OS_NAME}.sh

# Install Vim/Neovim
install $VIM $VIM_VERSION

# Install other requirements
if [[ -d "$HOME/themis/bin" ]]; then
  echo "Use a cache version $HOME/themis/bin"
else
  git clone --depth 1 --single-branch https://github.com/thinca/vim-themis "$HOME/themis"
fi
pip3 install --user vim-vint
pip3 install --user covimerage
