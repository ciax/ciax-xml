#!/bin/bash
# Gen2 command generator
mkitem(){
    echo -n "${1%)}"
    [[ "$*" =~ \$num ]] && echo -n '[n]'
}
mkcol(){
    while : ; do
        for (( i=0; i < 4; i++ )); do
            read a || { [ $i -gt 0 ] && echo; break 2; }
            echo -n $'\t'
            mkitem $a
        done
        echo
    done > /dev/stderr
}
usage(){
    echo "Usage: ${0##*/} [cmd]" > /dev/stderr
    egrep '^ +[a-z]+\)' $me | mkcol
    exit 1
}
mkcmd(){
    args="'EXEC TSC NATIVE CMD=\"$*\"'"
    echo "$args $TIMEOUT"
}
selcmd(){
    id="$1"
    shift
    num=$(printf %02d ${1:-1})
    TIMEOUT=10;
    case "$id" in
        login) mkcmd 1A1901ciax%%%%%%%%%%%%%%%% CIAX%%%%%%%%%%%% dummyunit dummyMenu dummyMessage;;
        logout) mkcmd 1A1902;;
        init)  mkcmd 1A1011;;
        tsconly) mkcmd 1A1008TSCONLY;;
        tscpri) mkcmd 1A1008TSCPRI%;;
        ron) mkcmd 904013;;
        roff) mkcmd 904014;;
        jon) mkcmd 132001ON%;;
        joff) mkcmd 132001OFF;;
        jres) mkcmd 132008;;
        rhook) TIMEOUT=180 mkcmd 132004;;
        runhk) TIMEOUT=180 mkcmd 132005;;
        rstop) mkcmd 104011;;
        ajup) TIMEOUT=180 mkcmd 932001;;
        ajdw) TIMEOUT=180 mkcmd 932002;;
        ajstop) mkcmd 932003;;
        jup) TIMEOUT=180 mkcmd 932004$num;;
        jdw) TIMEOUT=180 mkcmd 932005$num;;
        jstop) mkcmd 932006$num;;
        setinst) mkcmd 13200700$num;;
        *) usage;;
    esac
}
me=${BASH_SOURCE[0]}
[ $me =  $0 ] && selcmd $*
