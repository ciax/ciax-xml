#!/bin/bash
[ -d ~/gen2 ] || { echo "NO gen2, exit";exit; }
source ~/gen2/conf/bashrc
#This will define environment variables that are needed.
#Until these variables are defined at user login, you must start level 0 manually:
omsrv="./remoteObjects/remoteObjectManagerSvc.py --log=$LOGHOME/ro_mgrsvc.log --output=$LOGHOME/ro_mgrsvc_stdout.log --loglevel=info --detach"
#To start up the web-based control GUI:
bmsrv="./bin/bm_web.py --config=ciax --host=192.168.132.4 --log=$LOGHOME/bm_web.log --detach"
if ps -ef|grep -v "grep"|grep -q "$omsrv" ; then
    echo "Gen2 Service is already running"
else
    cd $PYHOME
    $omsrv || { echo "Gen2 Service Startup Error"; exit 1; }
fi

if ps -ef|grep -v "grep"|grep -q "$bmsrv"; then
    echo "Web Boot Manager is already running"
else
    cd $HOME/gen2
    $bmsrv || { echo "Boot Manager Startup Error"; exit 1; }
    sleep 3
    gen2init-runlevel
fi
