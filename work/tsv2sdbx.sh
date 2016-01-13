#!/bin/bash
inc(){ ind="$ind  "; }
dec(){ ind="${ind:0:-2}"; }
puts(){
    echo "$ind$1"
}
prtf(){
    echo -n "$ind"
    printf "$@"
}

xmlhead(){
    puts '<?xml version="1.0" encoding="utf-8"?>'
    inc
    puts '<symbol id="ixe" label="MOIRCS Turret">'
    inc
}
mksdb(){
    prtf '<numeric class="%s" msg="%s" tolerance="%s">%s</numeric>\n' "$@"
}
open(){
    prtf '<table id="t%s">\n' $1
    inc
    id=$1
}
close(){
    dec
    puts "</table>"
}
xmltail(){
    close
    dec
    puts "</symbol>"
    dec
    puts "</sdb>"
}

ind=""
dldir=~/.var/download
sheet="moircs-filter"
tsvfile=$dldir/$sheet.tsv
# make xml
sdb=$dldir/sdb-mix.xml
id=''
xmlhead
while read tid t slot tor cls msg desc; do
    if [ "$id" != "$t" ]; then
        [ "$id" ] && close
        open $t
    fi
    mksdb $cls $msg $tor $slot
done < <(grep -v '^!' $tsvfile)
xmltail
