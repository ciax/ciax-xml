#!/bin/bash
[ "$1" ] || { echo "Usage: logcut [id] [date_from|-] (date_to)"; exit 1; }
files="$HOME/.var/device_$1_*.log";shift
if [ "$1" = '-' ] ; then
    shift
    if [ "$1" ] ; then
        st=$(date -d "$1" +%s)|| exit
    else
        st=$(date +%s)
    fi
    awk "\$1 < $st && /rcv:/ { print }" $files|tail -1
else
    st=$(date -d "$1" +%s) || exit
    cond="\$1 > $st"
    shift
    if [ "$1" ] ; then
        st=$(date -d "$1" +%s)|| exit
        cond="$cond && \$1 < $st"
    fi
    awk "$cond && /rcv:/ { print }" $files
fi
