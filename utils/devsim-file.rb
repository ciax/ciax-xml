#!/bin/bash
[ "$1" ] ||{  echo "Usage:devsim-file [site]";exit 1; }
site=$1;shift
tty=$(tty)
read input < $tty
cmd=$(echo -n "$input"|base64)
while read line ;do
    if [ "$cmd" ]; then
        echo $line
        [[ "$line" =~ "$cmd" ]] && unset cmd
    else
        echo "$line"
        read input < $tty
        cmd=$(echo -n "$input"|base64)
    fi
done <  ~/.var/stream_${site}_2013.log
echo "No find $cmd"
