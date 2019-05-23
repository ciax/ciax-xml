#!/bin/bash
# Usage: gen2exe (-b) [command]
#  exe              : Show latest process exit code
#  exe [command]    : Foreground execution
#  exe -b           : Show active background process id
#  exe -b [command] : Background execution
# command is exclusive
#link exe
exitfile=~/.var/exit.txt
pidfile=~/.var/pid.txt
exelog=~/.var/gen2log.txt
[ -f $exitfile ] || echo "0" > $exitfile
[ -f $pidfile ] || touch $pidfile
loghead(){
    echo -en "[$(date +%F_%T)]% $@ " >> $exelog
}
doexe(){
    # Error output should be separated
    eval $* 2>> $exelog
    code="$?"
}
setexit(){
    echo "$code" > $exitfile
    echo " [exitcode=$code]" >> $exelog
}
updexit(){
    code=$(< $exitfile)
    [ "$code" = "0" ] || echo "0" > $exitfile
    echo $code
}
updpid(){
    sleep 0.1
    pid=$(< $pidfile)
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
bgexe(){
    pid=$(<$pidfile)
    if [ "$1" ] ; then
        [ "$pid" ] && reject "$@" || { bglog "$@" & updpid; }
    fi
    [ "$pid" ] || pid=0
    echo $pid
}
case "$1" in
    '')
        updexit
        ;;
    -b) # bg -> return pid, duplicated -> reject and pid 
        shift
        bgexe "$@"
        ;;
    -v) #For maintenance
        cat $exelog
        ;;
    *) 
        fglog "$@"
        ;;
esac
