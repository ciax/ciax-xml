#!/bin/bash
# Usage: gen2exe (-b) [command]
# -b:back ground execution with command
#   :check the life of latest background process 
# command is exclusive
#link exe
exit=~/.var/exit.txt
pid=~/.var/pid.txt
gen2log=~/.var/gen2log.txt
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
                    echo "[$(date +%D-%T)]" >> $gen2log
                    echo "% $* ($$)" >> $gen2log
                    echo "$$" > $pid
                    eval $* >> $gen2log 2>&1
                    echo "$?" > $exit
                    echo -e "[exitcode=$(cat $exit)]\n" >> $gen2log
                    : > $pid #clear
                } & echo "0"
            fi
        elif [ -s $pid ] ; then
            # Back ground task is alive when $pid is not empty
            cat $pid
        else
            echo "0"
        fi;;
    '') cat $exit;;
    *)
        echo "[$(date +%D-%T)]" >> $gen2log
        echo "% $*" >> $gen2log
        eval $* >> $gen2log 2>&1
        echo "$?"|tee $exit
        echo -e "[exitcode=$(cat $exit)]\n" >> $gen2log
        ;;
esac

