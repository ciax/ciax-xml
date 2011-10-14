#!/bin/bash
while getopts "kd" opt; do
    case $opt in
        d) iocmd="frmsim %id";;
        k) psg -k frmint;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
[ "$1" ] || psg frmint
for id; do
    d -r -t $id frmint -s $id ${iocmd/%id/$id}
done
