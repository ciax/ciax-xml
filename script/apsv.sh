#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
[ "$1" = "-s" ] && { shell=1;shift; }
id="$1"
setfld $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo "Connect to [$iodst]" >&2
if [ "$dmy" ] ; then
    iocmd="frmsim $id"
    id="dmy-$id"
else
    iocmd="socat - $iodst"
fi
if [ "$shell" ] ; then
    apserver $cls $id 0 "$iocmd"
else
    echo "Listen port [udp:$port]" >&2
    errlog="$HOME/.var/err-$id.log"
    date >> $errlog
    apserver $cls $id $port "$iocmd" >> $errlog 2>&1 &
fi
