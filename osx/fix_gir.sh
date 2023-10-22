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

export PATH=$HOME/.new_local/bin:$HOME/gtk/inst/bin:$PATH

# Seems like the build system changed for introspection. We now get many
# gir files without the prefix/full path to the library.
# We want the prefixes. We'll edit them manually later in build_app to point
# to the ones we include. 
# TEMP=$(openssl rand -hex 12)
WORKDIR=$(mktemp -d)
for i in $(find $HOME/gtk/inst/share/gir-1.0 -name *.gir); do
	echo Checking: ${i}
	cat ${i} | grep "shared-library" || true
	if [ `grep shared-library=\"lib* ${i}` ]; then
        gir=$(echo $(basename $i))
		echo Fixing: ${gir}
		typelib=${gir%.*}.typelib
		echo Processing $gir to ${WORKDIR}/$typelib

		cat $i | sed s_"shared-library=\""_"shared-library=\"$HOME/gtk/inst/lib/"_g > ${WORKDIR}/$gir
		cp ${WORKDIR}/$gir $HOME/gtk/inst/share/gir-1.0
		$HOME/gtk/inst/bin/g-ir-compiler ${WORKDIR}/$gir -o ${WORKDIR}/$typelib
	fi
done
cp ${WORKDIR}/*.typelib $HOME/gtk/inst/lib/girepository-1.0 2>/dev/null || :
rm -fr ${WORKDIR}

