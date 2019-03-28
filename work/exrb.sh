#!/bin/bash
files=${*:-lib*.rb}
for file in $files; do
    echo $file
    ./$file $ARGV
    [ $? = 1 ] && break
done
