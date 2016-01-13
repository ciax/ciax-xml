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

xmlheadi(){
    puts '<?xml version="1.0" encoding="utf-8"?>'
    puts '<idb xmlns="http://ciax.sum.naoj.org/ciax-xml/idb">'
    inc
    puts '<project id="moircs" label="MOIRCS" column="3">'
    inc
    puts '<group id="mc_turret" label="Turret control">'
    inc
    puts '<instance id="mix" app_id="ixe" host="moircsobcp" port="25607" label="Turret">'
    inc
    puts '<alias xmlns="http://ciax.sum.naoj.org/ciax-xml/idbc">'
    inc
}
xmlheads(){
    puts '<?xml version="1.0" encoding="utf-8"?>'
    inc
    puts '<symbol id="ixe" label="MOIRCS Turret">'
    inc
}

mkidb(){
    prtf '<item id="%s" label="%s for Turret %s ref="opt">\n' "$@"
    inc
}

mkpar(){
    puts "<argv>$1</argv>"
    puts "<argv>$2</argv>"
    dec
    puts "</item>"
}
mksdb(){
    prtf '<numeric class="%s" msg="%s" tolerance="%s">%s</numeric>\n' "$@"
}
openi(){
    prtf '<unit id="ut%s" title="[*]_%s" label="[FilterName]_%s">\n' $1 $1 $1
    inc
}
opens(){
    prtf '<table id="t%s">\n' $1
    inc
}
closei(){
    dec
    puts "</unit>"
}

closes(){
    dec
    puts "</table>"
}
    

ind=""
dldir=~/.var/download
sheet="moircs-filter"
tsvfile=$dldir/$sheet.tsv
# make xml
sdb=$dldir/sdb-mix.xml
idb=$dldir/idb-mix.xml

xmlheadi
id=''
while read tid t slot tor cls msg desc; do
    if [ "$id" != "$t" ]; then
        [ "$id" ] && closei
        openi $t
        id=$t
    fi
    mkidb "${msg,,*}_$t" "${desc:-$msg Filter}" $t
    mkpar $t $slot
done < <(grep -v '^!' $tsvfile)
closei
dec
puts "</alias>"
dec
puts "</instance>"
dec
puts "</group>"
dec
puts "</project>"
dec
puts "</idb>"

id=''
xmlheads
while read tid t slot tor cls msg desc; do
    if [ "$id" != "$t" ]; then
        [ "$id" ] && closes
        opens $t
        id=$t
    fi
    mksdb $cls $msg $tor $slot
done < <(grep -v '^!' $tsvfile)
closes
dec
puts "</symbol>"
dec
puts "</sdb>"
