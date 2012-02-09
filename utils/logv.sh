#!/bin/bash
while read ; do
    case $REPLY in
        1*)
            set - $REPLY
            time=`date -d @$1 +"%F %X"`
            echo "$time [$2] "
            echo $3|base64 -d|hd
            ;;
        *)
            echo $REPLY
            ;;
    esac
done
