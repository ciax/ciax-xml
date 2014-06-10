#!/bin/bash
jset(){
    IFS=}{,
    for i in $1;do
        [ "$i" ] || continue
        a=${i#*\"}
        eval "${a//\":/=}"
    done
    IFS=
}
getcmd(){
    input=$(head -1|base64|head -c-3)
}
[ "$1" ] ||{  echo "Usage:${0##*/} [site]";exit 1; }
site=$1;shift
getcmd
while read -u 3 line ;do
    jset $line
    if [ "$input" ]; then
        [[ "$base64" =~ "$input" ]] && unset input
    elif [[ "$dir" =~ rcv ]]; then
        echo -n "$base64"|base64 -d
        getcmd
    fi
done 3< <(grep -h . ~/.var/stream_${site}_*.log)
echo "No find $cmd" > /dev/stderr

