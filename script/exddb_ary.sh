#!/bin/bash
rmfld(){
    rm "$HOME/.var/field_${1}.mar"
}

rmfld mix
for i in 1 2 3 4 5 6; do
    exddb mix chkr $i
    exddb mix getp $i
done

rmfld crt
for i in 0 1 2 3 4 5; do
    for j in 0 1 2 3; do
        exddb crt get_tbl $i $j
    done
done
