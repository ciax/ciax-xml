#!/bin/bash
. ~/lib/libcsv.sh
obj="$1"
setfld -s $obj || _usage_key
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
devshell $dev "socat - $iodst" $obj
