#!/bin/bash
shopt -s nullglob
db=$1;id=$2
[ "$db" ] || {
    echo "Usage: list-item [db] [id]"
    exit
}
set - ~/ciax-xml/$db-*.xml
[ -f "$1" ] || {
    echo "No such db $db"
    exit
}
[ "$id" ] || {
    echo "Usage: list-item $db [id]"
    list-db $db
    exit
}
file=~/ciax-xml/$db-$id.xml
[ -f $file ] || {
    echo "No file $file"
    list-db $db
    exit
}
while read dmy cmd label; do
    [ $dmy = '</command>' ] && break
    eval ${cmd%>}
    echo $id
done < <(egrep '<(item|/command)' $file)
