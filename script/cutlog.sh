#!/bin/bash
[ "$1" ] || { echo "Usage: cutlog [date_from|-] (date_to)"; exit 1; }
if [ "$1" = '-' ] ; then
    shift
    if [ "$1" ] ; then
        st=$(date -d "$1" +%s)|| exit
    else
        st=$(date +%s)
    fi
    awk "\$1 < $st && /rcv:getstat/ { print }"|tail -1
else
    st=$(date -d "$1" +%s) || exit
    cond="\$1 > $st"
    shift
    if [ "$1" ] ; then
        st=$(date -d "$1" +%s)|| exit
        cond="$cond && \$1 < $st"
        awk "$cond && /rcv:getstat/ { print }"
    else
        awk "$cond && /rcv:getstat/ { print }"|head -1
    fi
fi