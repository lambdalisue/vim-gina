install_vim() {
  local tag=$1
  local ext=$([[ $tag == "HEAD" ]] && echo "--HEAD" || echo "")
  brew update
  brew install luajit python3
  brew install vim \
      --with-luajit \
      --with-python3 \
      --without-perl \
      --without-ruby \
      $ext
}

install_nvim() {
  local tag=$1
  local ext=$([[ $tag == "HEAD" ]] && echo "--HEAD" || echo "")
  brew update
  brew install python3
  brew install neovim/neovim/neovim $ext
  pip install --user neovim
  pip3 install --user neovim
}

install() {
  local name=$1
  local tag=$2
  if [[ $name == "nvim" ]]; then
    install_nvim $tag
  else
    install_vim $tag
  fi
}
