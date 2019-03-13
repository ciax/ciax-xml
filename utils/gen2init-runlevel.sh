#!/bin/bash
# Gen2 Boot up levels
source ~/gen2/conf/bashrc
#ACCESS port 20000 for web page
#Press "Refresh"; you should see Level 0 running.  Press "Push Out".

#Alternatively, you can run the shell based one:
cd $GEN2HOME
./BootManager.py --config=ciax <<EOF
setup()
start(1)
start(2)
start(3)
start(4)
start(5)
EOF
