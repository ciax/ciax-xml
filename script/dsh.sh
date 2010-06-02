#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj="$1"
setfld $obj || _usage_key
[ "$iocmd" ] || _die "No entry in iocmd field"
echo " [$iocmd]" >&2 
devshell2 $dev "$iocmd"