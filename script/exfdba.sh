#!/bin/bash
for id in ${*:-mma mmc mix crt ml1 dts} ; do
    exfdbc $id getstat
    case $id in
        mma)
            for i in 1 2 3 4 5; do
                exfdbs mma in $i
            done;;
        mmc)
            for i in 1 2 3 4 5; do
                exfdbs mmc in $i
            done;;
        mix)
            for i in 1 2 3 4 5 6; do
                exfdbs mix chkrun $i
                exfdbs mix getp $i
                exfdbs mix getspd $i
                exfdbs mix getofs $i
            done;;
        crt)
            for i in 0 1 2 3 4 5; do
                for j in 0 1 2 3; do
                    exfdbs crt get_tbl $i $j
                done
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
