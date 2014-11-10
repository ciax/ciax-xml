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
timeout(){
    warn "Timeout for $input"
    unset input
    error=1
}
[ "$1" ] ||{  echo "Usage:${0##*/} [site] (ver)";exit 1; }
site=$1;shift
version=$1;shift
input=$(input64)
pass=0
num=0
nk=0
warn "Init"
trap 'timeout' 1
while [ $pass -lt 2 ]  ;do
    while read -u 3 line ;do
        jset $line
        [ "$version" -a "$version" != "$ver" ] && continue
        if [ "$input" ]; then
            if [[ "$dir" =~ snd ]] ; then
                num=$(( $num + 1 ))
                if [ $num -gt 1000 ] ; then
                    num=0
                    nk=$(( $nk + 1 ))
                    if [ $nk -gt 100 ] ; then
                        timeout
                        nk=0
                    fi
                    echo -n '.' > /dev/stderr
                fi
                [[ "$base64" =~ "$input" ]] && unset input
            fi
        elif [[ "$dir" =~ rcv ]]; then
            if [ "$error" ] ; then
                echo -n ''
            else
                echo -n "$base64"|base64 -d
            fi
            unset error
            input=$(input64) || exit 1
            pass=0
            num=0
            nk=0

        fi
    done 3< <(grep -h . ~/.var/stream_${site}_*.log)
    warn "Pass <$pass>"
    pass=$(( $pass + 1 ))
done
warn "No find $cmd"
