#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj="$1"
iskey $obj || _usage_key
iocmd=`lookup "$obj" iocmd` || _die "No entry in iocmd field"
port=`lookup "$obj" port` || _die "No entry in port field"
echo " [$iocmd] [$port]" >&2 
objserver $obj $port "$iocmd"