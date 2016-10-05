#!/bin/bash
# Get Log from Stream
#alias jlg
[ "$2" ] || { echo "Usage: ${0##*/} [(event|stream|status|input_?|server_?)_site] [date]"; exit 1; }
pfx=$1;shift
day=$1;shift
input="$HOME/.var/log/${pfx}_*.log"
utime=$(date -d $day +%s)
base=${utime:0:5}
egrep -h "$base|$(( $base + 1 ))" $input|json_logview
