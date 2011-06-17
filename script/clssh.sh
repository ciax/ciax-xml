#!/bin/bash
. ~/lib/libcsv.sh

[[ "$1" == -* ]] && { opt=$1;shift; }

id="$1"
setfld $id || _usage_key "(-dcplgs)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
iocmd="socat - $iodst"
output="viewing $obj|stprint"
case "$opt" in
    -d) iocmd="frmsim $id";id="dmy-$id";;
    -c) output="ascpck $id";;
    -*) output="viewing $opt $obj|v2s";;
    *);;
esac
clsshell $cls $id "$iocmd" "$output"
