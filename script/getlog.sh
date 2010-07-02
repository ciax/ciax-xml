#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj=$1;shift
dev=$(lookup $obj dev) || _usage_key '' "[date]"
file=$HOME/.var/device_${obj}_2010.log
date="$*"
stime=`date -d "$date" +%s`|| exit
(echo $stime;cat $file)|sort|grep -A 20 $stime|grep rcv:getstat|\
while read -r line ; do
    echo "$line"|devstat $dev getstat|objstat $obj|stv
done
