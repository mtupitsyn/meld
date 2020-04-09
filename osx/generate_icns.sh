#!/usr/bin/env bash

##
## gist from https://gist.github.com/ikey4u/659f38b4d7b3484d0b55de85a55a8154
##

inkscape=$(which inkscape)
insvg=../data/icons/hicolor/scalable/apps/org.gnome.meld.svg
output=meld

outdir=${output}.iconset
mkdir $outdir
for sz in 16 32 128 256 512
do
    echo "[+] Generete ${sz}x${sz} png..."
    $inkscape --without-gui --export-file ${outdir}/icon_${sz}x${sz}.png -w $sz -h $sz $insvg
    $inkscape --without-gui --export-file ${outdir}/icon_${sz}x${sz}@2x.png -w $((sz*2)) -h $((sz*2)) $insvg
done
iconutil --convert icns --output ${output}.icns ${outdir}
echo "[v] The icon is saved to ${output}.icns."
rm -rf ${outdir}
