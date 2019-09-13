#!/bin/bash
# Usage: gen2exe (-b) [command]
#  exe              : Show latest process exit code
#  exe [command]    : Foreground execution
#  exe -b           : Show active background process id
#  exe -b [command] : Background execution
# command is exclusive
# Description: Long term command should be done backgroup to update status
#link exe

doexe(){
    # Error output should be separated
    eval $args 2>> $exelog
    code="$?"
}

### Status functions ###
loghead(){
    echo -en "[$(date +%F_%T)]% $* " >> $exelog
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
    pid=$(< $pidfile)
    if [ "$pid" ]; then
        ps -ef | grep -v "$$ .* grep" | grep -qw $pid && return
    fi
    unset pid
    > $pidfile
}
killpid(){
    pid=$(< $pidfile)
    [ "$pid" ] && kill $pid
    unset pid
    > $pidfile
    echo 0
}
bglog(){
    doexe
    loghead "$args (pid=$(< $pidfile))"
    setexit
}
fglog(){
    args="$*"
    loghead "$args"
    doexe
    setexit
    echo $code
}
reject(){
    loghead "$args" "[Rejected by duplication!]\n"
}
# Check background running
# Back ground task is alive when $pidfile is not empty
bgexe(){
    args="$*"
    updpid
    if [ "$1" ] ; then
        if [ "$pid" ]; then
            reject
        else
            bglog &
            #sleep 0.1
            echo "$!" > $pidfile
            loghead "$args (pid=$!)\n"
            updpid
        fi
    fi
    echo ${pid:-0}
}
exitfile=~/.var/run/exit.txt
pidfile=~/.var/run/pid.txt
exelog=~/.var/log/gen2log.txt
[ -f $exitfile ] || echo "0" > $exitfile
[ -f $pidfile ] || touch $pidfile
case "$1" in
    '')
        updexit
        ;;
    -b) # bg -> return pid, duplicated -> reject and pid 
        shift
        bgexe "$*"
        ;;
    -v) #For maintenance
        cat $exelog
        ;;
    -k)
        killpid
        ;;

    *)
        fglog "$*"
        ;;
esac
