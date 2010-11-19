#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
id="$1"
setfld $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
if [ "$dmy" ] ; then
    iocmd="devsim $id"
    oid="dmy-$id"
else
    iocmd="socat - $iodst"
    oid=$id
fi
objshell $cls $id $oid "$iocmd"
