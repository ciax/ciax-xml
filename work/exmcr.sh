#!/bin/bash
chklog(){
    [ "$out" ] || return 0
    log=~/.var/log/error_$out.out
    grep . $log | egrep -iv 'duplicated|initiate|info' || return 0
    > $log
    return 1
}
settag(){
    cd ~/ciax-xml
    tag=$(date +%y%m%d)"-Success@$HOSTNAME(project=$PROJ)w/mos-sim"
    git status | grep nothing && git tag -f $tag
}
premot(){
    mos_sim -
    sleep 5
    dvexe -e tmc slot5
}
PROJ=dmcs
case "$1" in
    -l)
        premot
        # VER=event:saved
        dvsv -eb
        # export VER=event:loaded
        opt=nlwhlocalhost
        out=dvsv
        ;;
    -p)
        premot
        dvsv -pb
        opt=pn
        out=dvsv
        ;;
    -c)
        premot
        mcrsv -pnb
        opt=c
        out=mcrsv
        sleep 1
        ;;
    -e)
        premot
        opt=en
        ;;
    *)
        echo "Usage: exmcr -(e|c|p|l)"
        exit
        ;;
esac
mcrexe -$opt upd
if chklog; then
    while
        mcrexe -$opt cinit
        [ $? -gt 8 ]
    do echo "RETRY"
    done
    settag
fi
dvsv
mos_sim
