#!/bin/bash
. ~/lib/libcsv.sh
[[ "$1" == -* ]] && { opt=$1;shift; }
id="$1"
setfld $id || _usage_key "(-dlgs)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
iocmd="socat - $iodst"
output="h2s"
case "$opt" in
    -d)
        fh="$HOME/.var/field_"
        iocmd="frmsim $id"
        org=$id
        id="dmy-$id"
        cp $fh$org.json $fh$id.json
        ;;
    -*) output="viewing $opt $obj|v2s"
        ;;
    *) ;;
esac
frmshell $dev $id "$iocmd" "$output"
