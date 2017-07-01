install_vim() {
  local tag=$1
  local ext=$([[ $tag == "HEAD" ]] && echo "--HEAD" || echo "")
  brew update
  brew install lua
  brew instal python3
  brew install vim --with-lua --with-python3 $ext
}

install_nvim() {
  local tag=$1
  local ext=$([[ $tag == "HEAD" ]] && echo "--HEAD" || echo "")
  brew update
  brew install python3
  brew install neovim/neovim/neovim $ext
  pip install --user neovim
  pip3 install --user neovim
  export THEMIS_ARGS="-e -s --headless"
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
