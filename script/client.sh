#!/bin/bash
. ~/lib/libdb.sh entity
while getopts "fh" opt; do
    case $opt in
        f) offset="-1000";;
        h) offset="+1000";;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
id="$1"
host="${2:-localhost}"
port=`~/lib/libinsdb.rb $id|grep port` || { echo "(-fh) [id] [host]"; exit; }
port=${port//\"/}
port="$(( ${port#*:} $offset ))"
echo "Connect to $host:$port" >&2
socat READLINE udp:$host:$port
