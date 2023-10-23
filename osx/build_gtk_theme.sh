#!/bin/bash -x

set -o nounset
set -o errexit
set -o functrace

trap "exit" INT
failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

export PATH=$HOME/.new_local/bin:$HOME/gtk/inst/bin:$PATH

#FIXME: This theme is pretty big and can be significantly reduced in size for our need. Perhaps ask for volunteers.

curl -LSs https://raw.githubusercontent.com/vinceliuice/WhiteSur-gtk-theme/master/release/WhiteSur-Light-solid.tar.xz -o $HOME/Source/WhiteSur-Light-solid.tar.xz
curl -LSs https://raw.githubusercontent.com/vinceliuice/WhiteSur-gtk-theme/master/release/WhiteSur-Dark-solid.tar.xz -o $HOME/Source/WhiteSur-Dark-solid.tar.xz

(cd $HOME/Source && tar xf WhiteSur-Light-solid.tar.xz)
(cd $HOME/Source && tar xf WhiteSur-Dark-solid.tar.xz)

cp -RP $HOME/Source/WhiteSur-Light-solid $HOME/gtk/inst/share/themes
cp -RP $HOME/Source/WhiteSur-Dark-solid $HOME/gtk/inst/share/themes

cp $HOME/gtk/inst/share/themes/Mac/gtk-3.0/gtk-keys.css $HOME/Source/WhiteSur-Dark-solid/gtk-3.0/
cp $HOME/gtk/inst/share/themes/Mac/gtk-3.0/gtk-keys.css $HOME/Source/WhiteSur-Light-solid/gtk-3.0/