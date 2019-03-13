#!/bin/bash
# show oss print args
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
    *)
        echo "Usage: gen2prt (-c) [option]"
        echo "       all, iid, login, cfg"
        exit 1;;
esac
