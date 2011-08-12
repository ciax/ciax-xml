#!/bin/bash
. ~/lib/libcsv.sh
id="$1"
setfld $id || _usage_key
[ "$iodst" ] || _die "No entry in iodst field"
echo "Connect to [$iodst]" >&2
if [ "$dmy" ] ; then
    iocmd="frmsim $id"
    id="dmy-$id"
else
    iocmd="socat - $iodst"
fi
if [ "$shell" ] ; then
    apserver $cls $id "$iocmd"
else
    echo "Listen port [udp:$port]" >&2
    errlog="$HOME/.var/err-$id.log"
    date > $errlog
    apserver $cls $id "$iocmd" $port >> $errlog 2>&1 &
    client $id
    echo
    cat $errlog
    psg -k "$cls $id"
fi
