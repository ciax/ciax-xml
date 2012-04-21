#!/bin/bash
while getopts "kr" opt; do
    case $opt in
        k)
            psg -k inthex
            exit
            ;;
        r)
            ID=`psg inthex|sed 's/^.*-s //'`
            [ "$ID" ] && RES=1 || exit 1;;
        *)
            echo "hexsv -k(kill),-r(restart) [id]..."
            ;;
    esac
done
shift $(( $OPTIND -1 ))
if [ "$1" -o "$RES" ] ; then
    while read id; do
        daemon -r -t $id inthex -s $id
    done < <( { for i in $ID $*;do echo $i;done; }|sort -u )
    sleep 1
fi
psg inthex
