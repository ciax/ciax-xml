#!/bin/bash
getcmd(){
    read input
    echo "$input"|base64
}
[ "$1" ] ||{  echo "Usage:devsim-file [site]";exit 1; }
site=$1;shift
cmd="$(getcmd)"
while read line ;do
    if [ "$cmd" ]; then
        [[ "$line" =~ "$cmd" ]] && unset cmd
    else
        echo "$line"
        cmd="$(getcmd)"
    fi
done <  ~/.var/stream_${site}_*.log
echo "No find $cmd" > /dev/stderr
