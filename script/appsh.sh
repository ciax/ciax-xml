#!/bin/bash
while getopts "d" opt; do
    case $opt in
        d) export NOLOG=1;dmy=1;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
ver=iocmd:client${VER:+,$VER}
if [ "$dmy" ] ; then
    VER=$ver $1 "frmsim $1"
else
    VER=$ver appint $1
fi
