#!/bin/bash
. ~/lib/libcsv.sh
cmd="$1";shift
[ "$1" = "-d" ] && { dmy=1;shift; }
id="$1"
setfld $id || _usage_key "[start|stop] (-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo "Listen port [udp:$port]" >&2
echo "Connect to [$iodst]" >&2
if [ "$dmy" ] ; then
    iocmd="frmsim $id"
    id="dmy-$id"
else
    iocmd="socat - $iodst"
fi
case $cmd  in
    start) opt=-r ;;
    stop) opt=-k ;;
    *) exit ;;
esac
d $opt csvserver $cls $id $port "$iocmd"

