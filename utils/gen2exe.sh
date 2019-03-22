#!/bin/bash
# Usage: gen2exe (-b) [command]
#  exe              : Show latest process exit code
#  exe [command]    : Foreground execution
#  exe -b           : Show active background process id
#  exe -b [command] : Background execution
# command is exclusive
#link exe
exit=~/.var/exit.txt
pid=~/.var/pid.txt
#gen2log=/dev/stdout
gen2log=~/.var/gen2log.txt
[ -f $exit ] || echo "0" > $exit
[ -f $pid ] || touch $pid
exelog(){
    echo "[$(date +%D-%T)]"
    echo "% $@ ($$)"
    echo "$$" > $pid
    eval $* 2>&1
    code="$?"
    echo "$code" > $exit
    echo -e "[exitcode=$code]\n"
    : > $pid #clear
}
reject(){
    echo "Rejected" >&2
    code=1
}
case "$1" in
    -b)
        shift
        if [ "$1" ] ; then
            if [ -s $pid ]; then
                reject
            else
                exelog "$@" >> $gen2log & code=0
            fi
        elif [ -s $pid ] ; then
            # Back ground task is alive when $pid is not empty
            code=$(<$pid)
        else
            code=0
        fi;;
    '') code=$(<$exit);;
    *) exelog "$@" >> $gen2log;;
esac
echo $code
