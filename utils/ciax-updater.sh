#!/bin/bash
dir=~/ciax-xml
if [ -d $dir/.git ] ; then
    cd $dir;git pull
else
    cd
    [ -e ciax-xml.tgz ] && rm ciax-xml.tgz
    wget http://ciax.sum.naoj.org/dav/ciax-xml.tgz
    tar xvzf ciax-xml.tgz
fi
ciax-installer
