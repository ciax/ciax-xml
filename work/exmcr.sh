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

PROJ=dmcs
mos_sim -
sleep 5
dvexe -e tmc slot5
case "$1" in
    -l)
        # VER=event:saved
        dvsv -eb
        # export VER=event:loaded
        opt=nlwhlocalhost
        out=dvsv
        ;;
    -p)
        dvsv -pb
        opt=pn
        out=dvsv
        ;;
    -c)
        mcrsv -pnb
        opt=c
        out=mcrsv
        sleep 1
        ;;
    *)
        opt=en
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
