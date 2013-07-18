#!/bin/bash
. ~/lib/libdb.sh entity
n=${1:-*};shift
file=$HOME/.var/json/stat_$n.json
for i in $file ; do
    j=${i#*_}
    k=${j%.*}
    echo "### $k ###"
    ~/lib/libwatch.rb $k
    read -t 0 && break
done
