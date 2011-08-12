#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-d" ] && { dmy=1;shift; }
id="$1"
setfld $id || _usage_key "(-d)"
[ "$iodst" ] || _die "No entry in iodst field"
errlog="$HOME/.var/err-$id.log"
date > $errlog
echo "Listen port [udp:$port]" | tee -a $errlog >&2
echo "Connect to [$iodst]" | tee -a $errlog >&2
if [ "$dmy" ] ; then
    export NOLOG=1
    iocmd="frmsim $id"
else
    iocmd="socat - $iodst"
fi
clsint $cls $id "$iocmd" $port >> $errlog 2>&1 &
client $id
echo
cat $errlog
psg -k "$cls $id"
