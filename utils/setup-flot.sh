#!/bin/bash
# Required packages: make yui-compressor
clone(){
    git clone http://github.com/$1
}

[ -d ~/jslib ] || mkdir ~/jslib
cd ~/jslib

# Get Flot 
[ -d flot ] || clone flot/flot.git

# Register libs
for dir in */; do
    cd $dir
    git pull
    make
    mv *.min.js ~/ciax-xml/weblib/
done
