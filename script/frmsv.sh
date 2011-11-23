#!/bin/bash
while getopts "kd" opt; do
    case $opt in
        d) iocmd="frmsim %id";;
        k) psg -k intfrm;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
[ "$1" ] || psg intfrm
for id; do
    d -r -t $id intfrm -s $id ${iocmd/%id/$id}
done
