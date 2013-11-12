#!/bin/bash
target='stat_'
replace='status_'
for name ;do
    echo $name
    echo '.tables' | sqlite3 $name | tr ' ' "\n"|grep $target | while read old; do
        new=${old//$target/$replace}
        echo "alter table $old rename to $new;" | sqlite3 $name
    done
done
