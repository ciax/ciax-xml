#!/bin/bash
# List Sites in ~/.var
[ "$1" ] || {
    echo "Usage: ${0##*/} [prefix]"
    echo "    stream,sqlog,event"
    echo "    json/(field,status,watch,macro,record)"
    exit
}
shopt -s nullglob
for i in ~/.var/$1_*; do
        r="${i#*_}"
        echo "${r%.*}"
done | column
