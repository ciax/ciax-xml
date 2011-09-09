#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
setfld $id || _usage_key '' "[date_from|-] (date_to)"
file=$HOME/.var/device_${id}_2010.log
if [ "$1" ] ; then
    par="$*"
else
    par='-'
fi
cutlog $par < $file|\
    while read -r line ; do
    echo "$line"|frmstat $dev $id|appstat $app
    done
