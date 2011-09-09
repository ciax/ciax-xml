#!/bin/bash
. ~/lib/libcsv.sh
id="$1"
setfld $id || _usage_key
echo "Connect to $host:$port" >&2
socat READLINE udp:$host:$port
