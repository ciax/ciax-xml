#!/bin/bash
while getopts "k" opt; do
    case $opt in
        k) psg -k inthex;;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
if [ "$1" ] ; then
    for id; do
        d -r -t $id inthex -s $id
    done
    sleep 1
fi
psg inthex
