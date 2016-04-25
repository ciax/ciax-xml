#!/bin/bash
# Get Log from Stream
#alias jlg
[ "$2" ] || { echo "Usage: ${0##*/} [date] [site]"; exit 1; }
day=$1;shift
site=$1;shift
input="$HOME/.var/log/stream_${site}_*.log"
utime=$(date -d $day +%s)
grep -h ${utime:0:5} $input|json_logview
