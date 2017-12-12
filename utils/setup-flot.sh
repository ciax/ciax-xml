#!/bin/bash
# Required packages: make yui-compressor
[ -d ~/jslib ] || mkdir ~/jslib
cd ~/jslib
if [ ! -d flot ] ; then
    git clone http://github.com/flot/flot.git
fi
cd flot
git pull
make
mv *.min.js ~/ciax-xml/weblib/
