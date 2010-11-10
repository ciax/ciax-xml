#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
id="$1"
setfld -s $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst] (q:Quit, D^:Stop)" >&2
if [ "$dmy" ] ; then
    objshell $cls $id dmy-$id "devsim $id"
else
    objshell $cls $id $id "socat - $iodst"
fi
