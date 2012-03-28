#!/bin/bash
. ~/lib/libdb.sh entity
yappcmd=~/lib/libappcmd.rb
list(){
    $appcmd $1 2>&1 | grep "^ "| cut -d ':' -f 1
}
show(){
    for id ;do
        echo "$C2#### $id ####$C0"
        list $id|while read cmd; do
            echo "$C3$cmd$C0"
            $appcmd $id $cmd 1 1
        done
        read -t 0 && break
    done
}
out=`mktemp`
trap "rm $out" EXIT
$appcmd $* >$out 2>&1
case "$?$2:$1" in
    1:) show `list`;;
    2:*) show $1;;
    0*) cat $out;;
    *) $appcmd $*;;
esac
