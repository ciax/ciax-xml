#!/bin/bash
for obj in ${*:-mma mix crt ml1 dts dt2} ; do
    yes|exfdb $obj getstat
    case $obj in
        mma)
            for i in 1 2 3 4 5; do
                yes|exfdb mma in $i
            done;;
        mix)
            for i in 1 2 3 4 5 6; do
                yes|exfdb mix chkrun $i
                yes|exfdb mix getp $i
                yes|exfdb mix getspd $i
                yes|exfdb mix getofs $i
            done;;
        crt)
            for i in 0 1 2 3 4 5; do
                for j in 0 1 2 3; do
                    yes|exfdb crt get_tbl $i $j
                done
            done;;
        dts)
            for i in get ist jak inr log; do
                yes|exfdb dts ${i}stat
            done;;
        ds*)
            exfdb $obj getzerr
            exfdb $obj getzlen
            ;;
        *)
            yes|exfdb $obj;;
    esac
    read -n 1
done

