#!/bin/bash
. ~/lib/libcsv.sh
obj="$1"
setfld $obj || _usage_key
echo "Connect to $host:$port" >&2 
socat READLINE udp:$host:$port
