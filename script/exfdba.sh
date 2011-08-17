#!/bin/bash
for obj in ${*:-mma mmc mix crt ml1 dts} ; do
    exfdbc $obj getstat
    case $obj in
        mma)
            for i in 1 2 3 4 5; do
                exfdbs - mma in $i
            done;;
        mmc)
            for i in 1 2 3 4 5; do
                exfdbs - mmc in $i
            done;;
        mix)
            for i in 1 2 3 4 5 6; do
                exfdbs - mix chkrun $i
                exfdbs - mix getp $i
                exfdbs - mix getspd $i
                exfdbs - mix getofs $i
            done;;
        crt)
            for i in 0 1 2 3 4 5; do
                for j in 0 1 2 3; do
                    exfdbs - crt get_tbl $i $j
                done
            done;;
        dts)
            for i in get ist jak inr log; do
                exfdbs - dts ${i}stat
            done;;
        ds*)
            exfdbs - $obj getzerr
            exfdbs - $obj getzlen
            ;;
        *)
            exfdbs - $obj;;
    esac
    read -t 0 && break
done

