#!/bin/bash
#alias mkhtml
[ "$1" ] || { echo "Usage: make-html [site] [ctlunit].. or -"; exit; }
setup-www
id=$1
shift
tmp=$HOME/.var/temp.$(date +%s)
if libhtmlctl $id $* > $tmp; then
    file=$HOME/.var/json/$id.html
    mv $tmp $file
    echo "$file created"
else
    rm $tmp
fi
