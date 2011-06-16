#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
[ "$1" = "-c" ] && { out="ascpck $2";shift; }
id="$1"
setfld $id || _usage_key "(-d,c)"
[ "$iodst" ] || _die "No entry in iodst field"
echo "Listen port [udp:$port]" >&2
echo "Connect to [$iodst]" >&2
if [ "$dmy" ] ; then
    iocmd="frmsim $id"
    id="dmy-$id"
else
    iocmd="socat - $iodst"
fi
errlog="$HOME/.var/err-$id.log"
date >> $errlog
clsserver $cls $id $port "$iocmd" "$out" >> $errlog 2>&1 &
