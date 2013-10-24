#!/bin/bash
# Converting type of time field in Sqlog (String -> Numeric)
tempdir=~/.var/temp
[ -d $tempdir ] || mkdir $tempdir
n='[0-9]'
tform="$n$n$n$n$n$n$n$n$n$n\.$n\+"
for file ;do
    echo $file
    case $file in
        *.sq3)
            for i in `echo .tables|sqlite3 $file`; do
                echo ".dump $i"|sqlite3 $file| sed -e "s/'\($tform\)'/\1/" > $tempdir/$i
                (echo "drop table $i;";cat $tempdir/$i)|sqlite3 $file
                rm $tempdir/$i
            done
            ;;
        *.log)
            <$file sed -e "s/\"\($tform\)\"/\1/" > $tempdir/$file
            mv $tempdir/$file .
            ;;
    esac
done
