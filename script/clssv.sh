#!/bin/bash
. ~/lib/libcsv.sh
while getopts "d" opt; do
    case $opt in
        d) export NOLOG=1;dmy=1;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
id=$1;shift
errlog="$HOME/.var/err-$id.log"
date > $errlog
psg -k -q "clsint -s $id"
if [ "$dmy" ] ; then
    VER=client,server clsint -s $id "frmsim $id" >> $errlog 2>&1 &
else
    VER=client,server clsint -s $id >> $errlog 2>&1 &
fi
client $id
echo
cat $errlog
psg -k "clsint -s $id"

