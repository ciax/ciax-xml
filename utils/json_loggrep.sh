#!/bin/bash
# Get Log from Stream
#alias jlg
[ "$2" ] || { echo "Usage: ${0##*/} [date] [file prefix]"; exit 1; }
day=$1;shift
pfx="$1";shift
utime=$(date -d $day +%s)
base=${utime:0:5}
egrep -h "$base|$(( $base + 1 ))" $HOME/.var/log/$pfx*|json_logview
