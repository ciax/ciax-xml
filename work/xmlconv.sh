#!/bin/bash
for i in fdb-cjk*;do
#    text-filter $i xml_e2a './/rspframe//*[@*]' verify decode
    text-filter $i xml_e2a './/rspframe//*[@*]' verify decode
done
exit

for i in fdb*; do
    text-filter $i xml_e2a .//response/item verify decode
done
text-replace 'verify assign' 'assign ref' fdb*
for i in fdb*; do
    text-filter $i xml_a2ct .//assign index
    text-format $i
done
