#!/bin/bash
# Converting type of time field in Sqlog (String -> Numeric)
tempdir=~/.var/temp
[ -d $tempdir ] || mkdir $tempdir
n='[0-9]'
for file ;do
    rm $tempdir/*
    for i in `echo .tables|sqlite3 $file`; do
        echo ".dump $i"|sqlite3 $file| sed -e "s/'\($n$n$n$n$n$n$n$n$n$n\.$n$n$n\)'/\1/" > $tempdir/$i
        (echo "drop table $i;";cat $tempdir/$i)|sqlite3 $file
    done
done
