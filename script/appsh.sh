#!/bin/bash
while getopts "d" opt; do
    case $opt in
        d) iocmd="frmsim $2";;
        *);;
    esac
done
shift $(( $OPTIND -1 ))
VER=${VER:-init/} intapp $1 $iocmd
