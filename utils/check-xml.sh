#!/bin/bash
[ "$1" ] || { echo "USAGE:chkxml [xmlfiles]"; exit; }
sdir=$HOME/ciax-xml/schema
for i ; do
    case $i in
        *.xsd)
            schema=$sdir/XMLSchema.xsd;;
        ?db-*.xml)
            schema=$sdir/${i%%-*}.xsd;;
        *)
            echo "$1 isn't Target"
            continue;;
    esac
    xmllint --noout --schema $schema $i
done