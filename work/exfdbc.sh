#!/bin/bash
xmldir=~/ciax-xml
frmcmd=$xmldir/script/libfrmcmd.rb
show(){
    for site ;do
        echo "$C2#### $site ####$C0"
        for cmd in $(list-item fdb $site); do
            echo "$C3$cmd$C0"
            $frmcmd $site $cmd 1 1 | text-visible
        done
        read -t 0 && break
    done
}
out=`mktemp`
trap "rm $out" EXIT
$frmcmd $* >$out 2>&1
case "$?$2:$1" in
    4:*) show `list-db fdb`;; # For All Devices
    5:*) show $1;;   # For All Command of One Device
    0*) text-visible $out;; # For One Command of One Device
    *) $frmcmd $*;; # For Error Output
esac
