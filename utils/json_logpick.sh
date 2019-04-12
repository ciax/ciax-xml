#!/bin/bash
#alias jlp
function grepdir () { egrep -h $dir $1; }
[ "$1" = '-s' ] && { dir='snd'; shift; } || dir='rcv';
if id=$1; shift; then
    files=$(grep -l $dir $HOME/.var/log/stream_${id}_*.log|sort -r|grep .) || exit;
    if cmd=$1; shift; then
        files=$(grep -l $cmd $files) || exit;
        # The number counting from behind
        grepdir $files | { shift && tac || cat; } | egrep ${1:+-m $1} \"$cmd\";
    else
        grepdir $files;
    fi | tail -n 1;
else
    echo "Usage: ${0##*/} (-s:snd) [site] (cmd:par) (num)";
fi
