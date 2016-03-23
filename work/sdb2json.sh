#!/bin/bash
# Generate dictionary by sdb(xml)
[ -t 0 ] && { echo "Usage: sdb2json < sdb_file"; exit 1; }
while read name line; do
    if [ $name = '<table' ]; then
        eval "${line%\"*}\""
        file="dic-$id.json"
    elif [ $name = '</table>' ]; then
        echo "{${json%,}}" > ~/.var/json/$file
        echo "$file is generated"
        json=
    elif [[ $line =~ msg ]] ; then
        eval "${line%\"*}\""
        # Element with text must be in one line
        body="${line#*>}"
        body="${body%<*}"
        # Msg will be converted to upper case
        [ "$body" ] && json="$json\"$body\":\"${msg^^}\","
    fi
done
