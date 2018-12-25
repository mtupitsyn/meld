#!/bin/bash

trap "exit" INT

export MACOSX_DEPLOYMENT_TARGET=10.9
export PATH=$HOME/.local/bin:$HOME/gtk/inst/bin:$PATH

# brew install python2 ccache

pushd . > /dev/null
jhbuild bootstrap
jhbuild buildone libffi openssl python3 libxml2
(cd $HOME/gtk/inst/bin && touch itstool && chmod +x itstool)
$HOME/gtk/inst/bin/python3 -m ensurepip
$HOME/gtk/inst/bin/pip3 install six
PYTHON=$HOME/gtk/inst/bin/python3 jhbuild build
$HOME/gtk/inst/bin/pip3 install pyobjc-core
$HOME/gtk/inst/bin/pip3 install pyobjc-framework-Cocoa
$HOME/gtk/inst/bin/pip3 install py2app
(cd $HOME/gtk/inst/lib && ln -s libpython3.6m.dylib libpython3.6.dylib)
(cd $HOME/Source/gtk && ([ -d Mojave-gtk-theme ] || git clone https://github.com/vinceliuice/Mojave-gtk-theme.git))
(cd $HOME/Source/gtk/Mojave-gtk-theme && sed -i.bak 's/cp -ur/cp -r/' install.sh && ./install.sh  --dest $HOME/gtk/inst/share/themes)
popd


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



