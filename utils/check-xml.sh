#!/bin/bash
#alias chkxml
[ "$1" ] || { echo "USAGE:chkxml [xmlfiles]"; exit; }
sdir=$HOME/ciax-xml/schema
for i ; do
    case $i in
        *.xsd)
            schema=$sdir/XMLSchema.xsd;;
        *.xml)
            eval $(egrep -o 'xmlns[^>]+' $i|head -1)
            schema=$sdir/${xmlns##*/}.xsd
            ;;
        *)
            echo "$1 isn't Target"
            continue;;
    esac
    xmllint --noout --schema $schema $i
done
