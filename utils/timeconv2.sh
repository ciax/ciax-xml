#!/bin/bash
# Converting time field in Sqlog or Logfile (x 1000/Integer)
tempdir=~/.var/temp
[ -d $tempdir ] || mkdir $tempdir
n='[0-9]'
int="$n$n$n$n$n$n$n$n$n$n"
dec="$n$n$n"
conv(){
    sed -e "s/\($int\)\.\($dec\)$n*/\1\2/"
}

for file ;do
    echo $file
    case $file in
        *.sq3)
            for i in `echo .tables|sqlite3 $file`; do
                echo ".dump $i"|sqlite3 $file| conv > $tempdir/$i
                (echo "drop table $i;";cat $tempdir/$i)|sqlite3 $file
                rm $tempdir/$i
            done
            ;;
        *.log)
            <$file conv > $tempdir/$file
            mv $tempdir/$file .
            ;;
    esac
done
