#!/bin/bash
. ~/lib/libcsv.sh
objects=${1:-`lookup all id`};shift
for id in $objects; do
    setfld $id || _usage_key
    echo "$C2#### $id ####$C0"
    if [ "$1" ] ; then
        { aliasing $obj $* || exit; } | clscmd $cls
    else
        { aliasing $obj && clscmd $cls; } 2>&1 |grep " : "| while read cmd dmy; do
            echo "$C3$cmd$C0"
            { aliasing $obj $cmd 1 0 || break; } | clscmd $cls || break
        done
    fi
    read
done
