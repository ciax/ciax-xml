#!/bin/bash
[ "$1" ] || { echo "Usage: logcut [id] (date_from) (date_to)"; exit 1; }
files="$HOME/.var/frame_$1_*.log";shift
if [ "$1" ] ; then
    from=$(date -d "$1" +%s) || exit
    cond="\$1 > $from"
    shift
    if [ "$1" ] ; then
        to=$(date -d "$1" +%s)|| exit
        cond="$cond && \$1 < $to"
    fi
    awk "$cond && /rcv:/ { print }" $files
else
    grep "rcv:" $files
fi
