#!/bin/bash
xmldir=~/ciax-xml
appcmd=$xmldir/script/libappcmd.rb
list(){
    for f in $xmldir/adb-*.xml; do
        a=${f%.*}
        echo ${a##*-}
    done
}

show(){
    for site ;do
        echo "$C2#### $site ####$C0"
        while read dmy cmd dmy2; do
            eval $cmd
            echo "$C3$id$C0"
            $appcmd $site $id 1 1
        done < <(grep '<item' $xmldir/adb-$site.xml)
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
