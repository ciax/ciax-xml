#!/bin/bash
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
psg -k -q "appint -s $id"
ver=client,server${VER:+,$VER}
if [ "$dmy" ] ; then
    VER=$ver appint -s $id "frmsim $id" >> $errlog 2>&1 &
else
    VER=$ver appint -s $id >> $errlog 2>&1 &
fi
appcl $id
echo
cat $errlog
psg -k "appint -s $id"

