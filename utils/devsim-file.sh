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
[ "$1" ] ||{  echo "Usage:${0##*/} [site]";exit 1; }
site=$1;shift
input=$(input64)
search=0
while [ $search -lt 2 ]  ;do
    while read -u 3 line ;do
        jset $line
        if [ "$input" ]; then
            [[ "$base64" =~ "$input" ]] && unset input
        elif [[ "$dir" =~ rcv ]]; then
            echo -n "$base64"|base64 -d
            input=$(input64) || exit 1
            search=0
        fi
    done 3< <(grep -h . ~/.var/stream_${site}_*.log)
    search=$(( $search + 1 ))
done
echo "No find $cmd" > /dev/stderr

