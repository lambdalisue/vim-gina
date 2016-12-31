#!/bin/bash
tmp=$(mktemp -d)
if [[ "$VERSION" == "nvim"  ]]; then
    url=https://github.com/neovim/neovim
    git clone -q --depth 1 --single-branch $url $tmp
    cd $tmp
    make -j2 CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX:PATH=$HOME/neovim" CMAKE_BUILD_TYPE=Release
else
    url=https://github.com/vim/vim
    ext=$([ "$VERSION" == "HEAD" ] && echo '' || echo "-b $VERSION")
    git clone -q --depth 1 --single-branch $ext $url $tmp
    cd $tmp
    ./configure --prefix="$HOME/vim" \
        --enable-fail-if-missing \
        --with-features=huge \
        --enable-perlinterp \
        --enable-rubyinterp \
        --enable-pythoninterp \
        --enable-python3interp \
        --enable-luainterp
    make -j2
fi
make install
  
