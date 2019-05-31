#!/bin/bash
# GEN2 Environment setting
# usage: source gen2env
case `uname` in
    SunOS)
        OSS_SYSTEM=/app/OSS/GLOBAL_DEBUG/OSS_SYSTEM
        OSSL_LOG=/app/oss_data/OBS_NFS
        OSS_CMDPATH=/app/LOAD/DEBUG
        OSS_OBS_HOST=cxws
        PATH=$OSS_SYSTEM:$OSS_CMDPATH:$PATH
        cmd="OSST_ciaxTSCcommand"
        prt="OSSC_screenPrint"
        ;;
    Linux)
        if [ -d ~/gen2 ] ; then
            source ~/gen2/conf/bashrc
            [ -d "$PYTHONPATH" ] || { echo "NO OSS files"; exit; }
            g2prt=$PYTHONPATH/SOSS/status/screenPrint.py
            g2cmd=$PYTHONPATH/Gen2/client/g2cmd.py
        fi
        ;;
    *)
        echo "Not for this system"
        exit
        ;;
esac
