#!/bin/bash
while getopts "kd" opt; do
    case $opt in
        d) iocmd="frmsim %id";;
        k) psg -k intapp;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
[ "$1" ] || psg intapp
for id; do
    d -r -t $id intapp -s $id ${iocmd/%id/$id}
done
