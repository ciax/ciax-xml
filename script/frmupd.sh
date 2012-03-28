#!/bin/bash
. ~/lib/libdb.sh entity
id=$1;shift
setfld $id || _usage_key
output="$HOME/.var/json/field_${id}.json"
merging $output <<EOF
{"id":"$id"}
EOF
~/lib/libfrmrsp.rb -q $dev | merging $output
