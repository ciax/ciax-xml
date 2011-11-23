#!/bin/bash
while getopts "k" opt; do
    case $opt in
        k) psg -k inthex;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
[ "$1" ] || psg inthex
for id; do
    appsv $id
    d -r -t $id inthex -sc $id
done
