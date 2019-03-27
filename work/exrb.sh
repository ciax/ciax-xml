#!/bin/bash
files=${*:-*.rb}
for file in $files; do
    echo $file
    ./$file $ARGV
    [ $? = 1 ] && break
done
