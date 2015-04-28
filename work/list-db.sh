#!/bin/bash
[ "$1" ] || {
    echo "Usage: list-db [db]"
    exit
}
for f in ~/ciax-xml/$1-*.xml; do
    [ -f $f ] || continue
    a=${f%.*}
    echo ${a##*[-_]}
done
