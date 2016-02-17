#!/bin/bash
# Generate dictionary by sdb(xml)
[ -t 0 ] && { echo "Usage: sdb2json < sdb_file"; exit 1; }
while read name line; do
    [[ $line =~ \" ]] || continue
    eval "${line%\"*}\""
    if [ "$id" != "$prev" ]; then
        if [ "$json" ]; then
            echo "{${json%,}}" > "$file"
            json=
        fi
        file="dic-$id.json"
        prev=$id
    fi
    body="${line#*>}"
    body="${body%<*}"
    [ "$body" ] && json="$json\"$body\":\"$msg\","
done
if [ "$json" ]; then
    echo "{${json%,}}" > "$file"
    echo "$file is generated"
    json=
fi

