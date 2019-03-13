#!/bin/bash
# Prepare for CIAX daemon
gen2prt iid > /dev/null 2>&1 || {
    echo "* init"
    gen2mkcmd init|gen2cmd
    echo "* login"
    gen2mkcmd login|gen2cmd
    echo "* set ID"
    gen2mkcmd setinst 1|gen2cmd
    echo "* logout"
    gen2mkcmd logout|gen2cmd
}
gen2red

