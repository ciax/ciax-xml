#!/bin/bash
rmfld(){
    rm "$HOME/.var/field_${1}.mar"
}
for obj in ${*:-mma mix crt ml1} ; do
    rmfld $obj
    case $obj in
        mma)
            for i in 1 2 3 4 5; do
                exddb mma in $i
            done;;
        mix)
            for i in 1 2 3 4 5 6; do
                exddb mix chkr $i
                exddb mix getp $i
            done;;
        crt)
            for i in 0 1 2 3 4 5; do
                for j in 0 1 2 3; do
                    exddb crt get_tbl $i $j
                done
            done;;
        dts)
            for i in get ist jak inr log; do
                exddb dts ${i}stat
            done;;
        *)
            exddb $obj;;
    esac
done

