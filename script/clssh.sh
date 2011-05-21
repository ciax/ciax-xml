#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
[ "$1" = "-c" ] && { output="ascpck";shift; }
[ "$1" = "-p" ] && { output="viewing $2|stprint";shift; }

id="$1"
setfld $id || _usage_key "(-dcp)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
if [ "$dmy" ] ; then
    iocmd="frmsim $id"
    id="dmy-$id"
else
    iocmd="socat - $iodst"
fi
clsshell $cls $id "$iocmd" "$output"
