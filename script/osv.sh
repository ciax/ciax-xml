#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj="$1"
iskey $obj || _usage_key
iocmd=`lookup "$obj" iocmd` || _die "No entry in iocmd field"
echo " [$iocmd]" >&2 
objserver $obj 9999 "$iocmd"