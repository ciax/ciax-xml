#!/bin/bash
getcmd(){
    read input
    cmd=$(echo "$input"|base64)
    echo "$cmd" >/dev/stderr
}
[ "$1" ] ||{  echo "Usage:devsim-file [site]";exit 1; }
site=$1;shift
getcmd
while read -u 3 line ;do
    if [ "$cmd" ]; then
        [[ "$line" =~ "$cmd" ]] && unset cmd
    else
        echo "$line"
        getcmd
    fi
done 3< <(grep . ~/.var/stream_${site}_*.log)
echo "No find $cmd" > /dev/stderr
