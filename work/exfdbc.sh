#!/bin/bash
xmldir=~/ciax-xml
frmcmd=$xmldir/script/libfrmcmd.rb
show(){
    for site ;do
        echo "$C2#### $site ####$C0"
        for cmd in $(list-item fdb $site); do
            echo "$C3$cmd$C0"
            <$inp $frmcmd $site $cmd 1 1 | text-visible
        done
        read -t 0 && break
    done
}
out=`mktemp`
inp=`mktemp`
cat > $inp <<EOF
{
"data":{
"ipr":"1","ipl":"1",
"stat":"1",
"output":"1",
"p":["0"],"spd":["0"],"rmp":["0"],"ofs":["0"],
"t":[[],[[],["0"]]]
}
}
EOF
trap "rm $out $inp" EXIT
<$inp $frmcmd $* >$out 2>&1
case "$?$2:$1" in
    1:) show `list-db fdb`;; # For All Devices
    2:*) show $1;;   # For All Command of One Device
    0*) visi $out;; # For One Command of One Device
    *) $frmcmd $*;; # For Error Output
esac
