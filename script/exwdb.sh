#!/bin/bash
. ~/lib/libdb.sh entity
n=${1:-*};shift
file=$HOME/.var/json/stat_$n.json
for i in $file ; do
    basename $i
    ~/lib/libwtview.rb $* < $i
    read -t 0 && break
done
