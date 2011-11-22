#!/bin/bash
while getopts "k" opt; do
    case $opt in
        k) psg -k hexint;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
[ "$1" ] || psg hexint
for id; do
    appsv $id
    d -r -t $id hexint -sc $id
done
