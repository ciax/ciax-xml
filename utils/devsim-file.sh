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
warn(){
    echo $C1"DEVSIM"$C0":$*" > /dev/stderr
}
[ "$1" ] ||{  echo "Usage:${0##*/} [site]";exit 1; }
site=$1;shift
input=$(input64)
search=0
num=0
warn "Init"
trap 'warn "SIGINT"' 2
while [ $search -lt 2 ]  ;do
    while read -u 3 line ;do
        jset $line
        if [ "$input" ]; then
            if [[ "$dir" =~ snd ]] ; then
                num=$(( $num + 1 ))
                if [ $num -gt 10000 ] ; then
                    warn "Timeout for $input"
                    unset input
                    num=0
                fi
                [[ "$base64" =~ "$input" ]] && unset input
            fi
        elif [[ "$dir" =~ rcv ]]; then
            echo -n "$base64"|base64 -d
            input=$(input64) || exit 1
            search=0
            num=0
        fi
    done 3< <(grep -h . ~/.var/stream_${site}_*.log)
    warn "Pass <$search>"
    search=$(( $search + 1 ))
done
warn "No find $cmd"
