#!/bin/bash

trap "exit" INT

export MACOSX_DEPLOYMENT_TARGET=10.9
export PATH=$HOME/.local/bin:$HOME/gtk/inst/bin:$PATH

pushd . > /dev/null
jhbuild bootstrap
jhbuild buildone libffi openssl python3 libxml2
$HOME/gtk/inst/bin/python3 -m ensurepip
$HOME/gtk/inst/bin/pip3 install six
PYTHON=$HOME/gtk/inst/bin/python3 jhbuild build
$HOME/gtk/inst/bin/pip3 install pyobjc-core
$HOME/gtk/inst/bin/pip3 install pyobjc-framework-Cocoa
$HOME/gtk/inst/bin/pip3 install py2app
(cd $HOME/gtk/inst/lib && ln -s libpython3.6m.dylib libpython3.6.dylib)

(cd $HOME/Source/gtk && ([ -d Mojave-gtk-theme ] || git clone https://github.com/vinceliuice/Mojave-gtk-theme.git))
(cd $HOME/Source/gtk/Mojave-gtk-theme && sed -i.bak 's/cp -ur/cp -r/' install.sh && ./install.sh  --dest $HOME/gtk/inst/share/themes)
exit

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

cp -R ~/gtk/inst/ ~/gtk/inst.orig
rm -fr ~/gtk/inst/share/help
rm -fr ~/gtk/inst/share/doc
rm -fr ~/gtk/inst/share/info
rm -fr ~/gtk/inst//lib/python3.6/test
rm -fr ~/gtk/inst//include
rm -fr ~/gtk/inst//lib/python3.6/test/
rm -fr ~/gtk/inst//include 
rm -fr ~/gtk/inst//lib/python3.6/distutils/tests 
rm -fr ~/gtk/inst//lib/python3.6/unittest

popd


