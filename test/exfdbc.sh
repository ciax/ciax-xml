#!/bin/bash
. ~/lib/libdb.sh entity
frmcmd=~/lib/libfrmcmd.rb
list(){
    $frmcmd $1 2>&1 | grep "^ "| cut -d ':' -f 1
}
show(){
    for id ;do
        echo "$C2#### $id ####$C0"
        list $id|while read cmd; do
            echo "$C3$cmd$C0"
            <$inp $frmcmd $id $cmd 1 1 | visi
        done
        read -t 0 && break
    done
}
out=`mktemp`
inp=`mktemp`
cat > $inp <<EOF
{
"val":{
"ipr":"1","ipl":"1",
"stat":"1",
"output":"1",
"p":["0"],"spd":["0"],"rmp":["0"],"ofs":["0"],
"t":[[],[[],["0"]]]
}
}
EOF
trap "rm $out $inp" EXIT
$frmcmd $* >$out 2>&1
case "$?$2:$1" in
    1:) show `list`;;
    2:*) show $1;;
    0*) visi $out;;
    *) $frmcmd $*;;
esac
