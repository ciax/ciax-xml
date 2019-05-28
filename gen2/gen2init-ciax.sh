#!/bin/bash
# Prepare for CIAX daemon
gen2prt iid > /dev/null 2>&1 || {
    echo "* init"
    gen2cmd init
    echo "* login"
    gen2cmd login
    echo "* set ID"
    gen2cmd setinst 1
    echo "* logout"
    gen2cmd logout
}
gen2red

