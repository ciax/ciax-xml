#!/bin/bash
. ~/se/lib/libdb.sh cx_class
cls=${1:-det}
dev=$(lookup $cls dev) || _usage_key
input=~/.var/${dev}.mar
[ -e $input ] || _die "no input file"
output=~/.var/${cls}.mar
clsstat $cls < $input > $output &&
mar $output
