#!/bin/bash
for name ;do
    echo $name
    echo '.tables' | sqlite3 $name | tr ' ' "\n"|grep stat_ | while read old; do
        new=${old//_/us_}
        echo "alter table $old rename to $new;" | sqlite3 $name
    done
done
