#!/bin/bash
. gen2env
mkcmd(){ # (-b) [timeout] [commands]
    if [ "$1" = -b ] ; then
        shift
        TIMEOUT=180
        cmd="$cmd -b"
    fi
    args="'EXEC TSC NATIVE CMD=\"$*\"'"
    case `uname` in
        SunOS)
            cmd="$cmd $TIMEOUT $args";;
        Linux)
            cmd="$cmd $args $TIMEOUT";;
    esac
    echo $cmd >&2
}
TIMEOUT=10;
# Accept StdInput
tty -s || { read arg;set - $arg; }
[ "$1" ] || { echo "Usage: gen2cmd (-b) [rawcmd] | < input" >&2;exit; }
mkcmd $*
exelog $cmd
