#!/bin/bash
if [ -d ~/ciax-xml/.git ] ; then
    cd ~/ciax-xml
    git pull
    cd
else
    cd
    [ -e ciax-xml.tgz ] && rm ciax-xml.tgz
    wget http://ciax.sum.naoj.org/dav/ciax-xml.tgz
    tar xvzf ciax-xml.tgz
fi
register_files
clean_up
