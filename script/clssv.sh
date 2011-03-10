#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
id="$1"
setfld $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo "Listen port [udp:$port]" >&2
echo "Connect to [$iodst]" >&2
if [ "$dmy" ] ; then
    iocmd="frmsim $id"
    id="dmy-$id"
else
    iocmd="socat - $iodst"
fi
line="clsserver $cls $id $port \"$iocmd\""
exec $line &