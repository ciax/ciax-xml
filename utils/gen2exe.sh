#!/bin/bash
# Usage: gen2exe (-b) [command]
#  exe              : Show latest process exit code
#  exe [command]    : Foreground execution
#  exe -b           : Show active background process id
#  exe -b [command] : Background execution
# command is exclusive
#link exe
exit=~/.var/exit.txt
pidfile=~/.var/pid.txt
exelog=~/.var/gen2log.txt
[ -f $exit ] || echo "0" > $exit
[ -f $pidfile ] || touch $pidfile
loghead(){
    echo -en "[$(date +%F_%T)]% $@" >> $exelog
}
doexe(){
    # Error output should be separated
    eval $* 2>> $exelog
    code="$?"
}
setexit(){
    echo "$code" > $exit
    echo " [exitcode=$code]" >> $exelog
}
updexit(){
    code=$(< $exit)
    [ "$code" = "0" ] || echo "0" > $exit
    echo $code
}
bglog(){
    echo "$$" > $pidfile
    loghead "$@" "(pid=$$)\n"
    doexe "$@"
    loghead "(pid=$$)"
    setexit
    > $pidfile
}
fglog(){
    loghead "$@"
    doexe "$@"
    setexit
    echo $code
}
reject(){
    loghead "$@" "[Rejected by duplication!]\n"
}
# Check background running
# Back ground task is alive when $pidfile is not empty
chkbg(){
    pid=$(<$pidfile)
    [ "$pid" ] && code=1 || code=0
    return $code
}
case "$1" in
    '')
        updexit
        ;;
    -b)
        shift
        if [ "$1" ] ; then
            if chkbg ; then
                bglog "$@" &
            else
                reject "$@"
            fi
        else
            chkbg
        fi
        echo $code;;
    -v) #For maintenance
        cat $exelog
        ;;
    *) fglog "$@";;
esac
