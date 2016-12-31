#!/bin/bash
set -ex
brew update
if [[ "$VERSION" == "nvim" ]]; then
    brew install neovim/neovim/neovim
else
    brew install lua
    brew install vim --with-lua
fi
