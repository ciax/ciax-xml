#!/bin/bash
. ~/lib/libcsv.sh
obj=$1;shift
setfld $obj || _usage_key '' "[date_from|-] (date_to)"
file=$HOME/.var/device_${obj}_2010.log
if [ "$1" ] ; then
    par="$*"
else
    par='-'
fi
cutlog $par < $file|\
    while read -r line ; do
    echo "$line"|devstat $dev $obj|clsstat $cls|objstat
    done
