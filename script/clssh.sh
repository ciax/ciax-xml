#!/bin/bash
. ~/lib/libcsv.sh

while getopts "d" o; do
    case $o in
        d) export NOLOG=1;dmy=1;;
        *) opt="$opt$o";;
    esac
done

shift $(( $OPTIND -1 ))

id="$1"
setfld $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
echo " [$iodst]" >&2
[ "$dmy" ] && iocmd="frmsim $id"
clsint ${opt:+"-$opt"} $id "$iocmd"
