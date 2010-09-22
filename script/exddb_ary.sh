#!/bin/bash
rmfld(){
    rm "$HOME/.var/field_${1}.mar"
}

rmfld mix
for i in 1 2 3 4 5 6; do
    exddb mix chkr $i
    exddb mix getp $i
done
