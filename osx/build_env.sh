#!/bin/bash

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

export MACOSX_DEPLOYMENT_TARGET=10.9
export PATH=$HOME/.new_local/bin:$HOME/gtk/inst/bin:$PATH

# brew install python2 ccache

pushd . > /dev/null
jhbuild bootstrap
jhbuild buildone libffi openssl python3 libxml2
(cd $HOME/gtk/inst/bin && touch itstool && chmod +x itstool)
$HOME/gtk/inst/bin/python3 -m ensurepip
$HOME/gtk/inst/bin/pip3 install six
PYTHON=$HOME/gtk/inst/bin/python3 jhbuild build --nodeps --ignore-suggests -s freetype-no-harfbuzz
$HOME/gtk/inst/bin/pip3 install pyobjc-core
$HOME/gtk/inst/bin/pip3 install pyobjc-framework-Cocoa
$HOME/gtk/inst/bin/pip3 install py2app
(cd $HOME/gtk/inst/lib && ln -s libpython3.6m.dylib libpython3.6.dylib)
(cd $HOME/Source/gtk && ([ -d Mojave-gtk-theme ] || git clone https://github.com/vinceliuice/Mojave-gtk-theme.git))
(cd $HOME/Source/gtk/Mojave-gtk-theme && sed -i.bak 's/cp -ur/cp -r/' install.sh && ./install.sh  --dest $HOME/gtk/inst/share/themes)
(cd $HOME/gtk/inst/share/themes && ln -sf Mojave-dark-solid-alt Meld-Mojave-dark)
(cd $HOME/gtk/inst/share/themes && ln -sf Mojave-light-solid-alt Meld-Mojave-light)

cd $HOME/Source
curl -OL https://gitlab.gnome.org/GNOME/gtksourceview/-/archive/4.4.0/gtksourceview-4.4.0.tar.bz2
tar xvf gtksourceview-4.4.0.tar.bz2
WORKDIR=$(mktemp -d)
cd $WORKDIR
jhbuild run meson --libdir lib --buildtype release --optimization 3 -Dgtk_doc=false -Db_bitcode=true -Db_ndebug=true -Dvapi=false $HOME/Source/gtk/gtksourceview-4.4.0
ninja install

popd


# Seems like the build system changed for introspection. We now get many
# gir files without the prefix/full path to the library.
# We want the prefixes. We'll edit them manually later in build_app to point
# to the ones we include. 
WORKDIR=$(mktemp -d)
for i in $(find $HOME/gtk/inst/share/gir-1.0 -name *.gir); do
	if [ `grep shared-library=\"lib* ${i}` ]; then
        gir=$(echo $(basename $i))

		typelib=${gir%.*}.typelib
		echo Processing $gir to ${WORKDIR}/$typelib

		cat $i | sed s_"shared-library=\""_"shared-library=\"$HOME/gtk/inst/lib/"_g > ${WORKDIR}/$gir
		cp ${WORKDIR}/$gir $HOME/gtk/inst/share/gir-1.0
		$HOME/gtk/inst/bin/g-ir-compiler ${WORKDIR}/$gir -o ${WORKDIR}/$typelib
	fi
done
cp ${WORKDIR}/*.typelib $HOME/gtk/inst/lib/girepository-1.0
rm -fr ${WORKDIR}


exit
# At some point, I'd like to see how this would perform. pypy3 can already be used during development
# however, py2app isn't really setup to use it directly. I'll check it out when I get the time.

[ -f $HOME/gtk/inst/bin/pypy3 ] || {
	cd $HOME/Source && curl -O -L https://bitbucket.org/pypy/pypy/downloads/pypy3-v6.0.0-osx64.tar.bz2
	tar xf pypy3-v6.0.0-osx64.tar.bz2
	rsync -r $HOME/Source/pypy3-v6.0.0-osx64/* $HOME/gtk/inst
	cd  $HOME/gtk/inst/bin
	ln -s pypy3 python
	ln -s pypy3 python3
	./pypy3 -m ensurepip
	./pip3 install -U pip
	./pip3 install six
	touch itstool && chmod +x itstool		#dummy itstool to compile gtk-doc
}



