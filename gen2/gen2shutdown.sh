#!/bin/bash
[ -d ~/gen2 ] || { echo "NO gen2, exit";exit; }
source ~/gen2/conf/bashrc

cd $GEN2HOME
./BootManager.py --config=ciax <<EOF
shutdown()
EOF
echo "Gen2 server is shutting down"
cd $HOME/gen2
./bin/bm_web.py --kill
echo "Web Boot Manager is shutting down"

