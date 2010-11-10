#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
id="$1"
setfld -s $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst] (D^ for Stop)" >&2
if [ "$dmy" ] ; then
    clsshell $cls dmy-$id "devsim $id"
else
    clsshell $cls $id "socat - $iodst"
fi
