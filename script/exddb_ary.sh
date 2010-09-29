#!/bin/bash
for obj in ${*:-mma mix crt ml1 dts} ; do
    yes|exddb $obj getstat
    case $obj in
        mma)
            for i in 1 2 3 4 5; do
                yes|exddb mma in $i
            done;;
        mix)
            for i in 1 2 3 4 5 6; do
                yes|exddb mix chkr $i
                yes|exddb mix getp $i
            done;;
        crt)
            for i in 0 1 2 3 4 5; do
                for j in 0 1 2 3; do
                    yes|exddb crt get_tbl $i $j
                done
            done;;
        dts)
            for i in get ist jak inr log; do
                yes|exddb dts ${i}stat
            done;;
        *)
            yes|exddb $obj;;
    esac
    read -n 1
done

