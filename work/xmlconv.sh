#!/bin/bash
for i ;do
    text-filter $i xml_e2a './/rspframe//*[@*]' verify decode
    text-filter $i xml_e2a './/response/item/*' verify decode
    ALL=1 text-replace 'verify assign' 'assign ref' $i
    text-filter $i xml_a2ct .//assign index
    text-filter $i xml_a2et .//field/array/index size
    text-format $i
done
