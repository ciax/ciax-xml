#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-`lookup all cls`};shift
for cls in $devices; do
    echo "#### $cls ####"
    if [ "$1" ] ; then
        clscmd $cls $*
    else
        clscmd $cls 2>&1 |grep : | while read line; do
            cmd=${line%:*}
            echo " ** $cmd **"
            clscmd $cls $cmd 1 0
        done
    fi
    read
done
