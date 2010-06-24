#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj="$1"
setfld $obj || _usage_key
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
devshell $dev "socat - $iodst"