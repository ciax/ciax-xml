#!/bin/bash
while getopts "kd" opt; do
    case $opt in
        d) iocmd="frmsim %id";;
        k) psg -k appint;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
[ "$1" ] || psg appint
for id; do
    d -r -t $id appint -s $id ${iocmd/%id/$id}
done
