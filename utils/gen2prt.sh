#!/bin/bash
case `uname` in
    SunOS)
        OSS_SYSTEM=/app/OSS/GLOBAL_DEBUG/OSS_SYSTEM
        OSSL_LOG=/app/oss_data/OBS_NFS
        OSS_CMDPATH=/app/LOAD/DEBUG
        OSS_OBS_HOST=cxws
        PATH=$OSS_SYSTEM:$OSS_CMDPATH:$PATH
        cmd="OSSC_screenPrint"
       ;;
    Linux)
        PYTHONPATH=~/gen2/share/Git/python
        [ -d "$PYTHONPATH" ] || { echo "NO OSS files"; exit; }
        cmd="$PYTHONPATH/SOSS/status/screenPrint.py"
        ;;
esac
cfg=~/drivers/config/cfg_tscst.txt
[ "$1" = -r ] && { shift; opt=-R; }
case "$1" in
    -c)
        if [ -f $cfg ] ; then
            $cmd $opt `grep -v "^#" $cfg| cut -d, -f1`|visible
        else
            echo "No CFG File"
        fi
        ;;
    all)
        $cmd $opt CXWS.TSCV.TELDRIVE CXWS.TSCV.0_SENSOR CXWS.TSCV.POWER_V2 CXWS.TSCV.POWER_V1 CXWS.TSCV.CIAX_MLP3_FAULT CXWS.TSCS.EL CXWS.TSCS.INSROT TSCV.InsRotRotation TSCV.RotatorType TSCV.TSC.LOGIN0 TSCV.TSC.LOGIN1 TSCV.TSC.LOGIN2 TSCV.TSC.LOGIN3 CXWS.TSCV.SHUTTER CXWS.TSCV.STOW_1 CXWS.TSCL.Z_SENSOR
        ;;
    iid)
        $cmd $opt CXWS.TSCV.OBE_INR
        ;;
    login)
        $cmd $opt TSCV.TSC.LOGIN0 TSCV.TSC.LOGIN1 TSCV.TSC.LOGIN2 TSCV.TSC.LOGIN3
        ;;
    "")
        echo "Usage: gen2prt (-r,-c) [print]"
        echo "    all,iid,login,(rawcmd)"
        exit;;
    *)
        $cmd -R $*
        ;;
esac
