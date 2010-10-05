#!/bin/bash
. ~/lib/libcsv.sh
obj=$1;shift
dev=$(lookup $obj dev) || _usage_key '' "[date_from|-] (date_to)"
file=$HOME/.var/device_${obj}_2010.log
if [ "$1" ] ; then
    par="$*"
else
    par='-'
fi
cutlog $par < $file|\
    while read -r line ; do
    echo "$line"|devstat $dev getstat|objstat $obj|stv
    done
