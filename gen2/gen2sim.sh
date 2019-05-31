#!/bin/bash
# Usage: gen2sim [command]
#  Gen2 command simulator
# test dummy
g2cmd-f(){
    echo "(Command simulator) $*" >/dev/stderr
    [ "$1" ] && w=$(( ${!#} / 10 )) || w=0.1
    sleep $w
}
g2prt-f(){
    CXWS_TSCV_TELDRIVE=12
    CXWS_TSCV_0_SENSOR=5f
    CXWS_TSCV_POWER_V2=000$(date +%3N)000000000353000000000317000000000509000000000448000000000430000000000440000000000464000000000412000000000392000000000319000000000492000000000431000000000500000000000463000000000447000000
    CXWS_TSCV_POWER_V1=0015dddddddddddddddd00000000000000000000ffff
    CXWS_TSCV_CIAX_MLP3_FAULT=10
    CXWS_TSCS_EL=89.962415
    CXWS_TSCS_INSROT=0.$(date +%6N)
    TSCV_InsRotRotation=02
    TSCV_RotatorType=10
    TSCV_TSC_LOGIN0=TWS2
    TSCV_TSC_LOGIN1=
    TSCV_TSC_LOGIN2=
    TSCV_TSC_LOGIN3=
    CXWS_TSCV_SHUTTER=a0
    CXWS_TSCV_STOW_1=05
    CXWS_TSCL_Z_SENSOR=000477000000000000000000000000000000000925000000
    CXWS_TSCV_OBE_INR=0005
    # Iterative output to pipe breaks read() data at a new line.
    #  -> One time output by temp file
    tmpfile=~/.var/$$.tmp
    for i ; do
        id=${i//./_}
        set|egrep "^$id" >/dev/null 2>&1 || continue
        echo ${!id}
    done > $tmpfile
    cat $tmpfile
    rm $tmpfile
}
cmd=${0##*/}-f
type $cmd >/dev/null 2>&1 && $cmd "$@"
