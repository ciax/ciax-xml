#!/bin/bash
[ "$1" ] || { echo "Usage: ${0##*/} [dir..]"; exit; }
for i ; do
    [ -d "$i" ] || mkdir "$i"
    cd "$i"
done
