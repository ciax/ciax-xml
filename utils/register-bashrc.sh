#!/bin/bash
# "Usage: ${0##*/} (-r)"
# Register bashrc
cd
src="source $HOME/bin/ciax-bashrc"
tmp=".$(date +%s).tmp"
if [ "$1" = "-r" ] ; then
    grep -q "$src" .bashrc || exit
    grep -v "$src" .bashrc > $tmp
    mv $tmp .bashrc
else
    grep -q "$src" .bashrc && exit
    echo $src >> .bashrc
fi
echo ".bashrc is modified"
