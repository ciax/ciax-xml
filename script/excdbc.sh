#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" ] && { setfld $1 || _usage_key; }
objects=${1:-`lookup all id`};shift
for id in $objects; do
    setfld $id || continue
    [ "$cls" ] || continue
    echo "$C2#### $id ####$C0"
    if [ "$1" ] ; then
        al=$( aliasing $obj $* ) && clscmd $cls $al
    else
        while read cmd dmy; do
            echo "$C3$cmd$C0"
            al=$( aliasing $obj $cmd 1 0 ) &&  clscmd $cls $al
        done < <( { aliasing $obj && clscmd $cls; } 2>&1 |grep " : " )
    fi
    read -t 0 && break
done
