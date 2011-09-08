#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" ] && { appcmd $1 upd > /dev/null || exit; }
apps=${1:-`appcmd 2>&1 | grep ' :' | cut -d ':' -f 1`};shift
for id in $apps; do
    echo "$C2#### $id ####$C0"
    if [ "$1" ] ; then
        appcmd $id $*
    else
        while read cmd dmy; do
            echo "$C3$cmd$C0"
            appcmd $id $cmd 1 1
        done < <( appcmd $id 2>&1 |grep " : " )
    fi
    read -t 0 && break
done
