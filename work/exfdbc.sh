#!/bin/bash
xmldir=~/ciax-xml
frmcmd=$xmldir/script/libfrmcmd.rb
getfid(){ # Get frame id fron ddb site
    grep "id=\"$1\"" $xmldir/ddb-*.xml | tr ' ' "\n"| grep frm_id
}
show(){
    for site ;do
        echo "$C2#### $site ####$C0"
        eval $(getfid $site)
        for cmd in $(list-item fdb $frm_id); do
            echo "$C3$cmd$C0"
            $frmcmd -r $site $cmd 1 1 | text-visible
        done
        read -t 0 && break
    done
}
out=`mktemp`
trap "rm $out" EXIT
$frmcmd $* >$out 2>&1
case "$?$2:$1" in
    4:*) show `list-db ddb`;; # For All Devices
    5:*) show $1;;   # For All Command of One Device
    0*) text-visible $out;; # For One Command of One Device
    *) $frmcmd $*;; # For Error Output
esac
