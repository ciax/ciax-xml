#!/bin/bash
[ "$1" ] || {
    echo "Usage: list-db [db]"
    exit
}
files=~/ciax-xml/$1-*.xml
case "$1" in
    adb) egrep '<app' $files;;
    fdb) egrep '<frame' $files;;
    idb|ddb) egrep '<site' $files;;
    *);;
esac | tr ' ' "\n"| grep '^id='|cut -d'"' -f2
