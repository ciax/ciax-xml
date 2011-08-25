#!/bin/bash
. ~/lib/libcsv.sh

while getopts "d" opt; do
    case $opt in
        d) export NOLOG=1;dmy=1;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
if [ "$dmy" ] ; then
    VER=iocmd:client clsint $1 "frmsim $1"
else
    VER=iocmd:client clsint $1
fi
