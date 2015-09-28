#!/bin/bash
JQUERY=1.7.2
[ "$1" ] || { echo "Usage: make-html [site].."; exit; }
setup-www
dir=$HOME/.var/json
tmpfile="$dir/temp"
for id; do
    file=$dir/$id.html
    libhtmltbl $id > $tmpfile || break
    html-enclose < $tmpfile > $file
    echo "$file created"
done
rm $tmpfile
