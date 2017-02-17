#!/bin/bash
set -x
export PATH="$HOME/neovim/bin:$HOME/vim/bin:$PATH"
if [[ -d /tmp/vim-themis ]]; then
    export THEMIS_HOME="/tmp/vim-themis"
    export PATH="/tmp/vim-themis/bin:$PATH"
fi
if [[ "$VERSION" == "nvim" ]]; then
    export THEMIS_VIM="nvim"
    export THEMIS_ARGS="-e -s --headless"
else
    export THEMIS_VIM="vim"
fi

uname -a
which -a $THEMIS_VIM
which -a python
which -a vint
which -a themis

$THEMIS_VIM --version
$THEMIS_VIM --cmd "try | helptags doc/ | catch | cquit | endtry" --cmd quit

python --version
vint --version
vint autoload/gina
vint autoload/vital/__gina__
vint plugin
vint ftplugin

themis --version
themis --reporter spec --runtimepath /tmp/vital
