#!/bin/bash
. ~/lib/libcsv.sh
id="$1"
setfld -s $id || _usage_key
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
objshell $cls $id "socat - $iodst"
