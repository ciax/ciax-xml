#!/bin/bash
while getopts "kr" opt; do
    case $opt in
        k)
            psg -k inthex
            exit
            ;;
        r)
            KILL=1
            ID=`psg inthex|sed 's/^.*-s //'`
            ;;
        *)  ;;
    esac
done
shift $(( $OPTIND -1 ))
if [ "$1" -o "$ID" ] ; then
    for id in $ID $*; do
        [ "$KILL" ] && psg -t -q inthex.+$id
        d -r -t $id inthex -s $id
    done
    sleep 1
else
    echo "hexsv -k(kill),-r(restart) [id]..."
fi
psg inthex
