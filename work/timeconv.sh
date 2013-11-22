#!/bin/bash
# Converting time field in Sqlog or Logfile (x 1000/Integer)
[ "$1" ] || {
    echo "Usage: timeconv (-t:test) [file(*.sq3,log) ...]"
    exit;
}
if [ "$1" = '-t' ]; then
    shift
    _test=1
fi
tempdir=~/.var/temp
[ -d $tempdir ] || mkdir $tempdir
n='[0-9]'
int="$n$n$n$n$n$n$n$n$n$n"
conv(){
    sed -e "s/['\"]*\($int\)\.*\($n\+\)\.*$n*['\"]*/\1\200/" | sed -e "s/\($int$n$n$n\)0*/\1/"
}

for file ;do
    echo $file
    case $file in
        *.sq3)
            for i in `echo .tables|sqlite3 $file`; do
                echo "   $i"
                echo ".dump $i"|sqlite3 $file| conv > $tempdir/$i
                if [ "$_test" ] ; then
                    cat $tempdir/$i
                else
                    (echo "drop table $i;";cat $tempdir/$i)|sqlite3 $file
                fi
                rm $tempdir/$i
            done
            ;;
        *.log)
            <$file conv > $tempdir/$file
            if [ "$_test" ] ; then
                cat $tempdir/$file
                rm $tempdir/$file
            else
                mv $tempdir/$file .
            fi
            ;;
    esac
done
