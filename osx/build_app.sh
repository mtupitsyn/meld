#!/bin/sh

export PATH=$HOME/.local/bin:$HOME/gtk/inst/bin:$PATH

APP="$PWD/dist/Meld.app"
MAIN="$APP/"
RES="$MAIN/Contents/Resources/"
FRAMEWORKS="$MAIN/Contents/Frameworks/"
INSTROOT="$HOME/gtk/inst/"

cp osx/conf.py meld/conf.py

glib-compile-schemas data
python3 setup_py2app.py build
python3 setup_py2app.py py2app --use-faulthandler -a

# py2app copies all Python framework to target..
# too busy to figure out how to solve this at the moment. Let's just 
# delete the files after they've been copied.
rm -fr $FRAMEWORKS/Python.framework

# icon themes
mkdir -p $RES/share/icons
rsync -r -t --ignore-existing $INSTROOT/share/icons/Adwaita $RES/share/icons
rsync -r -t --ignore-existing $INSTROOT/share/icons/hicolor $RES/share/icons

# glib schemas
rsync -r -t  $INSTROOT/share/glib-2.0/schemas $RES/share/glib-2.0
cp data/org.gnome.meld.gschema.xml $RES/share/glib-2.0/schemas
(cd $RES/share/glib-2.0 && glib-compile-schemas schemas)
rsync -r -t  $INSTROOT/share/GConf/gsettings $RES/share/GConf

# pango
mkdir -p $RES/etc/pango
pango-querymodules |perl -i -pe 's/^[^#].*\///' > $RES/etc/pango/pango.modules
echo "[Pango]\nModuleFiles=./etc/pango/pango.modules\n" > $RES/etc/pango/pangorc

# gdk-pixbuf
rsync -r -t $INSTROOT/lib/gdk-pixbuf-2.0 $RES/lib
gdk-pixbuf-query-loaders  | sed s=\".*/lib/gdk-pixbuf-2.0=\"@executable_path/\.\./Resources/lib/gdk-pixbuf-2.0=  > $RES/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
(cd $MAIN/Contents && ln -sf Resources/lib .)

# GTK themes
mkdir -p $RES/share/themes
rsync -r -t $INSTROOT/share/themes/Default/ $RES/share/themes/Default
rsync -r -t $INSTROOT/share/themes/Mac/ $RES/share/themes/Mac
rsync -r -t $INSTROOT/share/gtksourceview-3.0 $RES/share
mkdir -p $RES/share/themes/Meld-Mojave-dark/gtk-3.0
mkdir -p $RES/share/themes/Meld-Mojave-light/gtk-3.0
rsync -r -t --ignore-existing $INSTROOT/share/themes/Mojave-dark-solid-alt/gtk-3.0 $RES/share/themes/Meld-Mojave-dark
rsync -r -t --ignore-existing $INSTROOT/share/themes/Mojave-light-solid-alt/gtk-3.0 $RES/share/themes/Meld-Mojave-light
cp $INSTROOT/share/themes/Mac/gtk-3.0/gtk-keys.css $RES/share/themes/Meld-Mojave-dark/gtk-3.0/gtk-keys.css
cp $INSTROOT/share/themes/Mac/gtk-3.0/gtk-keys.css $RES/share/themes/Meld-Mojave-light/gtk-3.0/gtk-keys.css

# meld specific resources
mkdir $RES/share/meld
rsync -r -t data/icons/* $RES/share/icons
rsync -r -t data/meld.css $RES/share/meld
rsync -r -t data/styles/meld-dark.xml $RES/share/gtksourceview-3.0/styles
rsync -r -t data/styles/meld-base.xml $RES/share/gtksourceview-3.0/styles

# update icon cache for Adwaita
pushd .
cd $RES/share/icons/Adwaita
gtk-update-icon-cache -f .
popd

# update icon cache for hicolor
pushd .
cd $RES/share/icons/hicolor
gtk-update-icon-cache -f .
popd

# DIRTY HACK FOR NOW
#pushd .
#cd $MAIN/Contents/MacOS
#ln -s ../Resources/share .
#popd

# copy main libraries
mkdir -p $RES/lib
rsync -r -t $INSTROOT/lib/gtk-3.0 $RES/lib
rsync -r -t $INSTROOT/lib/girepository-1.0 $RES/lib
rsync -r -t $INSTROOT/lib/gobject-introspection $RES/lib

# copy some libraries that py2app misses
mkdir -p $FRAMEWORKS
rsync -t $INSTROOT/lib/libglib-2.0.0.dylib $FRAMEWORKS/libglib-2.0.0.dylib
rsync -t $INSTROOT/lib/libcairo-gobject.2.dylib $FRAMEWORKS/libcairo-gobject.2.dylib
rsync -t $INSTROOT/lib/libcairo-script-interpreter.2.dylib $FRAMEWORKS/libcairo-script-interpreter.2.dylib
rsync -t $INSTROOT/lib/libcairo.2.dylib $FRAMEWORKS/libcairo.2.dylib
rsync -t $INSTROOT/lib/libpangocairo-1.0.0.dylib $FRAMEWORKS/libpangocairo-1.0.0.dylib
rsync -t $INSTROOT/lib/libatk-1.0.0.dylib $FRAMEWORKS/libatk-1.0.0.dylib
rsync -t $INSTROOT/lib/libgio-2.0.0.dylib $FRAMEWORKS/libgio-2.0.0.dylib
rsync -t $INSTROOT/lib/libgobject-2.0.0.dylib $FRAMEWORKS/libgobject-2.0.0.dylib
rsync -t $INSTROOT/lib/libpango-1.0.0.dylib $FRAMEWORKS/libpango-1.0.0.dylib
rsync -t $INSTROOT/lib/libpangoft2-1.0.0.dylib $FRAMEWORKS/libpangoft2-1.0.0.dylib
rsync -t $INSTROOT/lib/libgtk-3.0.dylib $FRAMEWORKS/libgtk-3.0.dylib
rsync -t $INSTROOT/lib/libgtksourceview-3.0.1.dylib $FRAMEWORKS/libgtksourceview-3.0.1.dylib
rsync -t $INSTROOT/lib/libgtkmacintegration-gtk3.2.dylib $FRAMEWORKS/libgtkmacintegration-gtk3.2.dylib

# rename script, use wrapper
#mv $MAIN/Contents/MacOS/Meld $MAIN/Contents/MacOS/Meld-bin
#rsync -t osx/meld.applescript $MAIN/Contents/MacOS/meld_wrapper
#mv $MAIN/Contents/MacOS/meld_wrapper $MAIN/Contents/MacOS/Meld
chmod +x $MAIN/Contents/MacOS/Meld
#chmod +x $MAIN/Contents/MacOS/Meld-bin

# unroot the library path
pushd .
cd $MAIN/Contents/
# Original from
# https://github.com/apocalyptech/eschalon_utils/blob/master/make-osx-apps.sh
#
# Modify library paths in the modules manually with install_name_tool
# Modified from tegaki create_app_bundle.sh
# Keep looping as long as we added more libraries
newlibs=1
while [ $newlibs -gt 0 ]; do
  newlibs=0
  for dylib in $(find . -name "*.so" -o -name "*.dylib"); do
    echo "Modifying library references in $dylib"
    changes=""
    for lib in `otool -L $dylib | egrep "($INSTROOT|libs/)" | awk '{print $1}'` ; do
      base=`basename $lib`
      changes="$changes -change $lib @executable_path/../Frameworks/$base"
      # Copy the library in if necessary
      if [ ! -f "$FRAMEWORKS/$base" ]; then
        echo "Copying in $lib"
        cp $lib $FRAMEWORKS
        # Loop again so we can pick up this library's dependencies
        newlibs=1
      fi
    done
    if test "x$changes" != x ; then
      if ! install_name_tool $changes $dylib ; then
        echo "Error for $dylib"
      fi
      install_name_tool -id @executable_path/../$dylib $dylib
    fi
  done
done

WORKDIR=$(mktemp -d)

for i in $(find $HOME/gtk/inst/share/gir-1.0 -name *.gir); do
    gir=$(echo $(basename $i))
    typelib=${gir%.*}.typelib
    echo Processing $gir to ${WORKDIR}/$typelib

    cat $i | sed s_"$HOME/gtk/inst/lib"_"@executable\_path/../Frameworks"_g > ${WORKDIR}/$gir
    $HOME/gtk/inst/bin/g-ir-compiler ${WORKDIR}/$gir -o ${WORKDIR}/$typelib

done

cp ${WORKDIR}/*.typelib ${RES}/lib/girepository-1.0

rm -fr ${WORKDIR}


#for dylib in $(find . -name "*.dylib"); do
#  echo "Adding @executable_path/../Frameworks/$dylib to Meld"
#  install_name_tool -add_rpath "@executable_path/../Frameworks/$dylib" $MAIN/Contents/MacOS/Meld
#done
popd
exit
# Create the dmg file..
hdiutil create -size 250m -fs HFS+ -volname "Meld Merge" myimg.dmg
hdiutil attach myimg.dmg
DEVS=$(hdiutil attach myimg.dmg | cut -f 1)
DEV=$(echo $DEVS | cut -f 1 -d ' ')
rsync  -avzh  $APP /Volumes/Meld\ Merge/
pushd .
(cd /Volumes/Meld\ Merge/ && ln -sf /Applications "Drag Meld Here")
popd

# Compress the dmg file..
cp osx/DS_Store /Volumes/Meld\ Merge/.DS_Store
hdiutil detach $DEV
hdiutil convert myimg.dmg -format UDZO -o meldmerge.dmg

# Cleanup
mkdir -p osx/Archives
mv meldmerge.dmg osx/Archives
#rm -f myimg.dmg
