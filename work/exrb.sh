#!/bin/bash
files=${*:-*.rb}
for file in $files; do
    echo $file
    ./$file
    [ $? = 1 ] && break
done
