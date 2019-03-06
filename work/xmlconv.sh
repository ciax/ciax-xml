#!/bin/bash
for i in fdb*;do
    text-filter $i xml_e2a .//rspframe verify decode
done
for i in fdb*; do
    text-filter $i xml_e2a .//response/item verify decode
done
text-replace 'verify assign' 'assign ref' fdb*
