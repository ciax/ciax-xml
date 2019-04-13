#!/bin/bash
# show oss print args
usage(){
    echo "Usage: ${0##*/} [option]" > /dev/stderr
    echo "       all, iid, login, cfg" > /dev/stderr
    exit 1
}

selprt(){
    case "$1" in
        cfg)
            cfg=~/drivers/config/cfg_tscst.txt
            if [ -f $cfg ] ; then
                echo `grep -v "^#" $cfg| cut -d, -f1`
            else
                echo "No CFG File"
            fi
            ;;
        all)
            echo CXWS.TSCV.TELDRIVE CXWS.TSCV.0_SENSOR CXWS.TSCV.POWER_V2 CXWS.TSCV.POWER_V1 CXWS.TSCV.CIAX_MLP3_FAULT CXWS.TSCS.EL CXWS.TSCS.INSROT TSCV.InsRotRotation TSCV.RotatorType TSCV.TSC.LOGIN0 TSCV.TSC.LOGIN1 TSCV.TSC.LOGIN2 TSCV.TSC.LOGIN3 CXWS.TSCV.SHUTTER CXWS.TSCV.STOW_1 CXWS.TSCL.Z_SENSOR
            ;;
        iid)
            echo CXWS.TSCV.OBE_INR
            ;;
        login)
            echo TSCV.TSC.LOGIN0 TSCV.TSC.LOGIN1 TSCV.TSC.LOGIN2 TSCV.TSC.LOGIN3
            ;;
        *) return 1;;
    esac
}
[ ${BASH_SOURCE[0]} =  $0 ] && { selprt $* || usage; }
