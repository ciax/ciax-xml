#!/bin/bash
rep(){
    dev=$1;shift
    for i in $c;do
        for cmd in $*;do
            exfdbs $dev $cmd $i
            read -t 0 && break
        done
    done
}
for id in ${*:-mma mmc mix crt ml1 dts} ; do
    case $id in
        mma)
            c='1 2 3 4 5' rep mma in;;
        mmc)
            c='1 2 3 4 5' rep mmc in;;
        mix)
            c='1 2 3 4 5' rep mix chkrun getp getspd getofs;;
        crt)
            for i in 0 1 2 3 4 5; do
                c='0 1 2 3' rep crt get_tbl:$i
            done;;
        dts)
            for i in get ist jak inr log; do
                exfdbs dts ${i}stat
            done;;
        ds*)
            exfdbs $id getzerr
            exfdbs $id getzlen
            ;;
        *)
            exfdbs $id;;
    esac
    read -t 0 && break
done
