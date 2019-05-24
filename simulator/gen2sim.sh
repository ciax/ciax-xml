#!/bin/bash
# Usage: gen2sim [command]
#  Gen2 command simulator
#link gen2cmd
#link gen2prt
# test dummy
g2cmd(){
    echo -n '(Command simulator)' >/dev/stderr
    gen2mkcmd "$@" >/dev/stderr
    sleep $(( ${2:-1} / 10 ))
}
g2prt(){
    CXWS_TSCV_TELDRIVE=12
    CXWS_TSCV_0_SENSOR=5f
    CXWS_TSCV_POWER_V2=000427000000000353000000000317000000000509000000000448000000000430000000000440000000000464000000000412000000000392000000000319000000000492000000000431000000000500000000000463000000000447000000
    CXWS_TSCV_POWER_V1=0015dddddddddddddddd00000000000000000000ffff
    CXWS_TSCV_CIAX_MLP3_FAULT=10
    CXWS_TSCS_EL=89.962415
    CXWS_TSCS_INSROT=0.001215
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
    id=${1//./_}
    echo ${!id}
}
case "$0" in
    *gen2cmd)
        g2cmd "$@" >/dev/stderr
        ;;
    *gen2prt)
        for i in $(gen2mkprt $*); do
            g2prt ${i//./_}
        done
        ;;
    *) ;;
esac


