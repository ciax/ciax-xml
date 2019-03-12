#!/bin/bash
chkenv(){
    case `uname` in
        SunOS)
            OSS_SYSTEM=/app/OSS/GLOBAL_DEBUG/OSS_SYSTEM
            OSSL_LOG=/app/oss_data/OBS_NFS
            OSS_CMDPATH=/app/LOAD/DEBUG
            OSS_OBS_HOST=cxws
            PATH=$OSS_SYSTEM:$OSS_CMDPATH:$PATH
            cmd="OSST_ciaxTSCcommand"
            ;;
        Linux)
            PYTHONPATH=~/gen2/share/Git/python
            [ -d "$PYTHONPATH" ] || { echo "NO OSS files"; exit; }
            cmd="$PYTHONPATH/Gen2/client/g2cmd.py"
            ;;
    esac
}
mkcmd(){ # (-b) [timeout] [commands]
    if [ "$1" = -b ] ; then
        shift
        TIMEOUT=180
        cmd="$cmd -b"
    fi
    args="'EXEC TSC NATIVE CMD=\"$*\"'"
    case `uname` in
        SunOS)
            cmd="$cmd $TIMEOUT $args";;
        Linux)
            cmd="$cmd $args $TIMEOUT";;
    esac
    echo $cmd >&2
}
TIMEOUT=10;
chkenv
# Accept StdInput
tty -s || { read arg;set - $arg; }
[ "$1" ] || { echo "Usage: gen2cmd (-b) [rawcmd] | < input" >&2;exit; }
mkcmd $*
exelog $cmd
