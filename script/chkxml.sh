#!/bin/bash
[ "$1" ] || { echo "USAGE:chkxml [xmlfiles]"; exit; }
sdir=$HOME/ciax-xml/schema
for i ; do
    [[ "$i" == ?db-*.xml ]] || { echo "$1 isn't Target"; continue; }
    db=${i%%-*}
    xmllint --noout --schema $sdir/$db.xsd $i
done