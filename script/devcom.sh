#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj="$1"
iskey $obj || _usage_key
iocmd=`lookup "$obj" iocmd` || _die "No entry in iocmd field"
file=~/.var/$obj.bin
echo " [$iocmd]" >&2 
exec $iocmd | tee $file
