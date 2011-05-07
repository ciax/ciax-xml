#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-`lookup all cls`};shift
for cls in $devices; do
    echo "$C2#### $cls ####$C0"
    if [ "$1" ] ; then
        clscmd $cls $*
    else
        clscmd $cls 2>&1 |grep " : "| while read cmd dmy; do
            echo "$C3$cmd$C0"
            clscmd $cls $cmd 1 0 || break
        done
    fi
    read
done
