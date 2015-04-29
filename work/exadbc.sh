#!/bin/bash
xmldir=~/ciax-xml
appcmd=$xmldir/script/libappcmd.rb
show(){
    for site ;do
        echo "$C2#### $site ####$C0"
        for id in $(list-item adb $site); do
            echo "$C3$id$C0"
            $appcmd $site $id 1 1
        done
    done
}
out=`mktemp`
trap "rm $out" EXIT
$appcmd $* >$out 2>&1
case "$?$2:$1" in
    1:) show `list-db adb`;;
    2:*) show $1;;
    0*) cat $out;;
    *) $appcmd $*;;
esac
