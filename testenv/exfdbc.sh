#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
for id in $devices; do
    setfld $id || _usage_key
    [ "$dev" ] || continue
    echo "$C2#### $dev($id) ####$C0"
    input="$HOME/.var/field_$id.json"
    if [ "$1" ] ; then
        frmcmd $dev $* | visi
    else
        frmcmd $dev 2>&1 |grep " : "| while read cmd dmy
        do
            echo -n "   $C3$cmd$C0 ";frmcmd $dev $cmd 1 0 < $input| visi
        done
    fi
done
