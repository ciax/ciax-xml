#!/bin/bash
. gen2env
cfg=~/drivers/config/cfg_tscst.txt
[ "$1" = -r ] && { shift; opt=-R; }
case "$1" in
    -c)
        if [ -f $cfg ] ; then
            $prt $opt `grep -v "^#" $cfg| cut -d, -f1`|visible
        else
            echo "No CFG File"
        fi
        ;;
    all)
        $prt $opt CXWS.TSCV.TELDRIVE CXWS.TSCV.0_SENSOR CXWS.TSCV.POWER_V2 CXWS.TSCV.POWER_V1 CXWS.TSCV.CIAX_MLP3_FAULT CXWS.TSCS.EL CXWS.TSCS.INSROT TSCV.InsRotRotation TSCV.RotatorType TSCV.TSC.LOGIN0 TSCV.TSC.LOGIN1 TSCV.TSC.LOGIN2 TSCV.TSC.LOGIN3 CXWS.TSCV.SHUTTER CXWS.TSCV.STOW_1 CXWS.TSCL.Z_SENSOR
        ;;
    iid)
        $prt $opt CXWS.TSCV.OBE_INR
        ;;
    login)
        $prt $opt TSCV.TSC.LOGIN0 TSCV.TSC.LOGIN1 TSCV.TSC.LOGIN2 TSCV.TSC.LOGIN3
        ;;
    "")
        echo "Usage: gen2prt (-r,-c) [print]"
        echo "    all,iid,login,(rawcmd)"
        exit;;
    *)
        $prt -R $*
        ;;
esac
