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
exelog=~/.var/gen2log.txt
[ -f $exit ] || echo "0" > $exit
[ -f $pid ] || touch $pid
loghead(){
    echo -e "[$(date +%D-%T)]% $@" >> $exelog
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
bglog(){
    loghead "$@" "(pid=$$)\n"
    echo "$$" > $pid
    code=0
    bgexe "$@" &
}
bgexe(){
    doexe "$@"
    loghead "(pid=$$)"
    setexit
    > $pid
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
# Back ground task is alive when $pid is not empty
chkbg(){
    code=$(<$pid)
    [ "$code" ] || code=0
    return $code
}
case "$1" in
    '')
        cat $exit
        echo "0" > $exit
        ;;
    -b)
        shift
        if [ "$1" ] ; then
            chkbg && bglog "$@" || reject "$@"
        else
            chkbg
        fi
        echo $code;;
    -v) #For maintenance
        cat $exelog
        ;;
    *) fglog "$@";;
esac
