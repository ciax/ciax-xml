#!/bin/bash
# Usage: gen2sim [command]
#  Gen2 command simulator
#link gen2cmd
#link gen2prt

# test dummy
slept(){
    echo -n '(Command simulator)' >/dev/stderr
    gen2mkcmd "$@" >/dev/stderr
    sleep $(( ${2:-1} / 10 ))
}
# gen2 command
g2cmd(){
    source ~/gen2/conf/bashrc
    $PYTHONPATH/Gen2/client/g2cmd.py "$@"
}
case "$0" in
    *gen2cmd)
        slept "$@"
        ;;
    *gen2prt)
        ;;
    *) ;;
esac
