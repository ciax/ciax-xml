#!/bin/bash
#Pick up by date from Json Log
#alias jld
[ "$2" ] || { echo "Usage: ${0##*/} [site] [date]"; exit 1; }
id=$1;shift
date=$1;shift
year=$(date -d $date +%Y)
sec=$(date -d $date +%s)
exp=:${sec:0:5}
egrep "$exp" ~/.var/log/stream_${id}_$year.log
