install_vim() {
  local URL=https://github.com/vim/vim
  local python=$1
  local tag=$2
  local ext=$([[ $tag == "HEAD" ]] && echo "" || echo "-b $tag")
  local tmp="$(mktemp -d)"
  local out="$HOME/cache/$python-vim-$tag"
  local ncpu=$(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo)
  git clone --depth 1 --single-branch $ext $URL $tmp
  cd $tmp
  if [[ $python == "2" ]]; then
    ./configure --prefix=$out \
        --enable-fail-if-missing \
        --with-features=huge \
        --enable-pythoninterp \
        --enable-luainterp
  elif [[ $python == "3" ]]; then
    ./configure --prefix=$out \
        --enable-fail-if-missing \
        --with-features=huge \
        --enable-python3interp \
        --enable-luainterp
  else
    ./configure --prefix=$out \
        --enable-fail-if-missing \
        --with-features=huge \
        --enable-luainterp
  fi
  make -j$ncpu
  make install
  ln -s $out $HOME/vim
}

install_nvim() {
  local URL=https://github.com/neovim/neovim
  local python=$1
  local tag=$2
  local ext=$([[ $tag == "HEAD" ]] && echo "" || echo "-b $tag")
  local tmp="$(mktemp -d)"
  local out="$HOME/cache/$python-nvim-$tag"
  local ncpu=$(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo)
  git clone --depth 1 --single-branch $ext $URL $tmp
  cd $tmp
  make -j$ncpu \
    CMAKE_BUILD_TYPE=Release \
    CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX:PATH=$out"
  make install
  if [[ $python == "2" ]]; then
    pip install --user neovim
  elif [[ $python == "3" ]]; then
    pip3 install --user neovim
  fi
  ln -sf $out $HOME/vim
}

install() {
  local python=$1
  local vim=$2
  local tag=$3
  [[ -d $HOME/vim ]] && rm -f $HOME/vim
  if [[ $tag != "HEAD" ]] && [[ -d "$HOME/cache/$python-$vim-$tag" ]]; then
    echo "Use a cached version '$HOME/cache/$python-$vim-$tag'."
    ln -sf $HOME/cache/$python-$vim-$tag $HOME/vim
    return
  fi
  if [[ $vim == "nvim" ]]; then
    install_nvim $python $tag
  else
    install_vim $python $tag
  fi
}
