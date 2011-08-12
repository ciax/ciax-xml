#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { daemon=1;shift; }
id="$1"
setfld $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo "Connect to [$iodst]" >&2
iocmd="socat - $iodst"
if [ "$daemon" ] ; then
    echo "Listen port [udp:$port]" >&2
    aprelay $obj "$iocmd" $port &
    client $id
    echo
    psg -k "$iocmd"
else
    aprelay $obj "$iocmd"
fi
