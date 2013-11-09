#/bin/bash
# option (-e): edit mode
if [ "$1" = -e ] ; then
    shift
    edit=1
fi
file=~/.var/sqlog_$1.sq3
if [ -e $file ] ;then
    sql="sqlite3 $file"
    if [ "$edit" ] ; then
        $sql
    elif libsqlog.rb $1|$sql ; then
        echo "OK"
    else
        tables=$(echo .tables|$sql)
        echo "TABLES=$tables"
        echo "SCHEMA="
        echo .schema|$sql
        echo "INPUTDATA="
        libsqlog.rb $1
    fi
else
    echo "Usage: sqltest (-e) [id]"
fi