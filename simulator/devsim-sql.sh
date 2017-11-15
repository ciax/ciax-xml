#!/bin/bash
nexttime(){
    sqlite3 $sqlfile <<EOF
select min(time) from stream
 where time > ${time:=0}
 and id == '$site'
 ${1:+and snd == '$1'}
;
EOF
}
next(){
    time=$(nexttime $input)
    [ "$time" ] || return 1
}
fields(){
    sqlite3 -line $sqlfile <<EOF | tr -d ' '
select * from stream
 where time == $time; 
EOF
}
setvar(){
    while read line; do
        eval "$line"
    done < <(fields)
}

warn(){
    echo $C1"DEVSIM"$C0":$*" > /dev/stderr
}

[ "$1" ] ||{  echo "Usage:${0##*/} [site] (ver)";exit 1; }
site=$1;shift
version=$1;shift
time=0
sqlfile="$HOME/.var/log/stream.sq3"
warn "Init"
trap 'timeout' 1
while : ; do
    input=$(input64)
    next || next || break
    setvar
    sleep $dur
    echo -n $rcv|base64 -d
done
warn "No find $cmd"
