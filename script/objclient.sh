#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj="$1"
setfld $obj || _usage_key
echo "Connect to $host:$port" >&2 
socat READLINE udp:$host:$port