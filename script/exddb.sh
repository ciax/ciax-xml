#!/bin/bash
. ~/se/lib/libdb.sh cx_object
devices=${1:-cf1 crt det dts cci mh1 mt3 mix map mma ml1};shift
defcmd="${*:-getstat}"
for obj in $devices; do
    export obj
    dev=$(lookup $obj dev) || _usage_key
    echo "#### $dev($obj) ####"
    input="$HOME/.var/device_${obj}_2010.log"
    cmd=$defcmd
    if [ $dev = slo ] ; then cmd=bs; fi
    str="`devcmd $dev $cmd`" || exit 1
    echo "$str" | visi
    grep "rcv:${cmd// /:}" $input|tail -1| devstat $dev $cmd|mar
done
