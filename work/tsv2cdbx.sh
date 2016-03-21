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
    puts '<cdb xmlns="http://ciax.sum.naoj.org/ciax-xml/cdb">'
    inc
    puts '<alias id="mix" label="MOIRCS Turret">'
    inc
}
mkidb(){
    prtf '<item id="%s" label="%s for Turret %s" ref="opt">\n' "$@"
    inc
}

mkpar(){
    puts "<argv>$1</argv>"
    puts "<argv>$2</argv>"
    dec
    puts "</item>"
}
open(){
    prtf '<unit id="ut%s" title="[*]_%s" label="[FilterName]_%s">\n' $1 $1 $1
    inc
    id=$1
}
close(){
    dec
    puts "</unit>"
}
xmltail(){
    close
    dec
    puts "</alias>"
    dec
    puts "</cdb>"
}    


ind=""
dldir=~/.var/download
sheet="moircs-filter"
tsvfile=$dldir/$sheet.tsv
# make xml
idb=$dldir/idb-mix.xml

xmlhead
id=''
while read tid t slot tor cls msg desc; do
    if [ "$id" != "$t" ]; then
        [ "$id" ] && close
        open $t
    fi
    mkidb "${msg,,*}_$t" "${desc:-$msg Filter}" $t
    mkpar $t $slot
done < <(grep -v '^!' $tsvfile)
xmltail
