#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
setfld $id || _usage_key
output="$HOME/.var/field_${id}.json"
merging $output <<EOF
{"id":"$id"}
EOF
frmstat -q $dev | merging $output
