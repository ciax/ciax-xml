#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
id="$1"
setfld -s $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst] with [$id]" >&2
if [ "$dmy" ] ; then
    devshell $dev dmy-$id "devsim $id"
else
    devshell $dev $id "socat - $iodst"
fi