#!/bin/bash
# UDP Client
#alias cl
while getopts "h:" opt; do
    case $opt in
        h) host="$OPTARG";;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
id="$1";shift
layer="$1";shift
host=${host:-localhost}
[ "$id" ] || echo "${0##*/} (-h host) [id] [layer]" >&2
while read line; do
    echo $line
    [ "$dup" ] && continue
    if [ "$port" ];then
        dup=1
        unset port
    else
        port=${line##*:}
    fi
done < <(echo "$id:$layer.*udp"|socat -t 0.01 - udp:$host:54321|egrep '[0-9].')
if [ "$port" ]; then
    echo "Connect to $host:$port" >&2
    nc -u $host $port
fi
