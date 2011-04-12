#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
[ "$1" = "-s" ] && { output="symboling";shift; }
[ "$1" = "-l" ] && { output="symboling|labeling";shift; }
[ "$1" = "-p" ] && { output="symboling|labeling|stprint";shift; }
id="$1"
setfld $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
if [ "$dmy" ] ; then
    fh="$HOME/.var/field_"
    iocmd="frmsim $id"
    org=$id
    id="dmy-$id"
    cp $fh$org.json $fh$id.json
else
    iocmd="socat - $iodst"
fi
frmshell $cls $id "$iocmd" "$output"
