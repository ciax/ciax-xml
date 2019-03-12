#!/bin/bash
# Usage: exe (-b|-p) [command]
# -b:back ground execution
# command is exclusive
#link exe
exit=~/.var/exit.txt
pid=~/.var/pid.txt
exelog=~/.var/exelog.txt
[ -f $exit ] || echo "0" > $exit
[ -f $pid ] || touch $pid
case "$1" in
    -b)
        shift
        if [ "$1" ] ; then
            if [ -s $pid ]; then
                echo "Rejected" >&2
                echo "1"
            else
                {
                    echo "[$(date +%D-%T)]" >> $exelog
                    echo "% $* ($$)" >> $exelog
                    echo "$$" > $pid
                    eval $* >> $exelog 2>&1
                    echo "$?" > $exit
                    echo -e "[exitcode=$(cat $exit)]\n" >> $exelog
                    : > $pid #clear
                } & echo "0"
            fi
        elif [ -s $pid ] ; then
            cat $pid
        else
            echo "0"
        fi;;
    '') cat $exit;;
    *)
        echo "[$(date +%D-%T)]" >> $exelog
        echo "% $*" >> $exelog
        eval $* >> $exelog 2>&1
        echo "$?"|tee $exit
        echo -e "[exitcode=$(cat $exit)]\n" >> $exelog
        ;;
esac

