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

curl -LSs https://codeload.github.com/vinceliuice/WhiteSur-icon-theme/tar.gz/refs/tags/2023-07-03 -o $HOME/Source/WhiteSur-icon-theme-2023-07-03.tar.gz
(cd $HOME/Source && tar xf WhiteSur-icon-theme-2023-07-03.tar.gz)

# Ths installer was never meant to install for macOS, so we have to craft our own version
# based on what's inside the installer shell script. 
# This: 
# ./install -d $HOME/gtk/inst/share/icons -n Meld-WhiteSur-Icons
# won't work for us..

# So the following is mostly based on install.sh that comes with the theme. 

SRC_DIR=$HOME/Source/WhiteSur-icon-theme-2023-07-03
theme=""
color="-dark"

THEME_NAME=Meld-WhiteSur-Icons
name=$THEME_NAME
THEME_DIR=$HOME/gtk/inst/share/icons/${THEME_NAME}
dest=$HOME/gtk/inst/share/icons
[[ -d ${THEME_DIR} ]] && rm -rf ${THEME_DIR}

echo "Installing to '${THEME_DIR}'..."

mkdir -p                                                                                   ${THEME_DIR}
cp -RP "${SRC_DIR}"/{COPYING,AUTHORS}                                                      ${THEME_DIR}
cp -RP "${SRC_DIR}"/src/index.theme                                                        ${THEME_DIR}

gsed -i "s/WhiteSur/Meld-Icons/g" ${THEME_DIR}/index.theme

mkdir -p                                                                                  ${THEME_DIR}/status
cp -RP "${SRC_DIR}"/src/{actions,animations,apps,categories,devices,emblems,mimes,places} ${THEME_DIR}
cp -RP "${SRC_DIR}"/src/status/{16,22,24,32,symbolic}                                     ${THEME_DIR}/status

cp -RP "${SRC_DIR}"/links/{actions,apps,categories,devices,emblems,mimes,places,status}   ${THEME_DIR}

if [[ ${theme} != '' ]]; then
    cp -RP "${SRC_DIR}"/colors/color${theme}/*.svg                                        ${THEME_DIR}/places/scalable
fi

if [[ ${color} == '-dark' ]]; then
    mkdir -p                                                                              ${THEME_DIR}/{apps,categories,emblems,devices,mimes,places,status}

    cp -cRP "${SRC_DIR}"/src/actions                                                       ${THEME_DIR}
    cp -cRP "${SRC_DIR}"/src/apps/symbolic                                                 ${THEME_DIR}/apps
    cp -cRP "${SRC_DIR}"/src/categories/symbolic                                           ${THEME_DIR}/categories
    cp -cRP "${SRC_DIR}"/src/emblems/symbolic                                              ${THEME_DIR}/emblems
    cp -cRP "${SRC_DIR}"/src/mimes/symbolic                                                ${THEME_DIR}/mimes
    cp -cRP "${SRC_DIR}"/src/devices/{16,22,24,symbolic}                                   ${THEME_DIR}/devices
    cp -cRP "${SRC_DIR}"/src/places/{16,22,24,symbolic}                                    ${THEME_DIR}/places
    cp -cRP "${SRC_DIR}"/src/status/{16,22,24,symbolic}                                    ${THEME_DIR}/status

    if [[ ${bold:-} == 'true' ]]; then
        cp -RP "${SRC_DIR}"/bold/*                                                              ${THEME_DIR}
    fi

    # if [[ $DESKTOP_SESSION == '/usr/share/xsessions/budgie-desktop' ]]; then
    #     cp -RP "${SRC_DIR}"/src/status/symbolic-budgie/*.svg                                    ${THEME_DIR}/status/symbolic
    # fi

    # Change icon color for dark theme
    find "${THEME_DIR}"/{actions,devices,places,status}/{16,22,24}/ -type f -exec gsed -i "s/#363636/#dedede/g" {} \;
    find "${THEME_DIR}"/actions/32/ -type f -exec gsed -i "s/#363636/#dedede/g" {} \;
    find "${THEME_DIR}"/{actions,apps,categories,emblems,devices,mimes,places,status}/symbolic -type f -exec gsed -i "s/#363636/#dedede/g" {} \;

    cp -cRPf "${SRC_DIR}"/links/actions/{16,22,24,32,symbolic}                                  ${THEME_DIR}/actions
    cp -cRPf "${SRC_DIR}"/links/devices/{16,22,24,symbolic}                                     ${THEME_DIR}/devices
    cp -cRPf "${SRC_DIR}"/links/places/{16,22,24,symbolic}                                      ${THEME_DIR}/places
    cp -cRPf "${SRC_DIR}"/links/status/{16,22,24,symbolic}                                      ${THEME_DIR}/status
    cp -cRPf "${SRC_DIR}"/links/apps/symbolic                                                   ${THEME_DIR}/apps
    cp -cRPf "${SRC_DIR}"/links/categories/symbolic                                             ${THEME_DIR}/categories
    cp -cRPf "${SRC_DIR}"/links/mimes/symbolic                                                  ${THEME_DIR}/mimes

    #TODO: Those are breaking.. Later though when we have some time..
    # cd ${dest}
    # ln -s ../${name}${theme}/animations ${name}${theme}-dark/animations
    # ln -s ../../${name}${theme}/categories/32 ${name}${theme}-dark/categories/32
    # ln -s ../../${name}${theme}/emblems/16 ${name}${theme}-dark/emblems/16
    # ln -s ../../${name}${theme}/emblems/22 ${name}${theme}-dark/emblems/22
    # ln -s ../../${name}${theme}/emblems/24 ${name}${theme}-dark/emblems/24
    # ln -s ../../${name}${theme}/mimes/16 ${name}${theme}-dark/mimes/16
    # ln -s ../../${name}${theme}/mimes/22 ${name}${theme}-dark/mimes/22
    # ln -s ../../${name}${theme}/mimes/scalable ${name}${theme}-dark/mimes/scalable
    # ln -s ../../${name}${theme}/apps/scalable ${name}${theme}-dark/apps/scalable
    # ln -s ../../${name}${theme}/devices/scalable ${name}${theme}-dark/devices/scalable
    # ln -s ../../${name}${theme}/places/scalable ${name}${theme}-dark/places/scalable
    # ln -s ../../${name}${theme}/status/32 ${name}${theme}-dark/status/32
fi

(
    cd ${THEME_DIR}
    ln -sf actions actions@2x
    ln -sf animations animations@2x
    ln -sf apps apps@2x
    ln -sf categories categories@2x
    ln -sf devices devices@2x
    ln -sf emblems emblems@2x
    ln -sf mimes mimes@2x
    ln -sf places places@2x
    ln -sf status status@2x
)

gtk-update-icon-cache ${THEME_DIR}
