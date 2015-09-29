#!/bin/bash
[ "$1" ] || { echo "Usage: make-html [site] [ctlunit].."; exit; }
setup-www
id=$1
shift
dir=$HOME/.var/json
file=$dir/$id.html
libhtmltbl $id $* > $file
echo "$file created"
