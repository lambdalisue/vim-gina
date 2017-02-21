#!/usr/bin/env bash

# Fail on unset variables and command errors
set -ue -o pipefail

# Prevent commands misbehaving due to locale differences
export LC_ALL=C

install_vim() {
  local py=$1
  local tag=$2
  local ext=$([[ $tag == "HEAD" ]] && echo "--HEAD" || echo "")
  brew update
  brew install lua
  brew instal python3
  if [[ $py == "2" ]]; then
    brew install vim --with-lua $ext
  elif [[ $py == "3" ]]; then
    brew install vim --with-lua --with-python3 $ext
  else
    brew install vim --with-lua --without-python $ext
  fi
}

install_nvim() {
  local py=$1
  local tag=$2
  local ext=$([[ $tag == "HEAD" ]] && echo "--HEAD" || echo "")
  brew update
  brew install python3
  brew install neovim/neovim/neovim $ext
  if [[ $py == "2" ]]; then
    pip install --user neovim
  elif [[ $py == "3" ]]; then
    pip3 install --user neovim
  fi
}

install() {
  local py=$1
  local name=$2
  local tag=$3
  if [[ $name == "nvim" ]]; then
    install_nvim $py $tag
  else
    install_vim $py $tag
  fi
}
