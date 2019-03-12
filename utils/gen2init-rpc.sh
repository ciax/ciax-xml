#!/bin/bash
# Gen2 Setup RPC environment
default=/etc/default/rpcbind
setdef(){
    if [ -f $default ] ;then
        if sudo grep 'OPTIONS="-w -i"' "$default"; then
            echo "Nothing to do on $default"
            return
        else
            echo "$default is updated"
        fi
    else
        echo "$default is created"
    fi
    echo 'OPTIONS="-w -i"' |sudo tee $default
}

if ps -ef|grep -v grep|grep -q rpcbind; then
    echo "rpcbind is running"
else
    echo "rpcbind is not running, exit"
    exit 1
fi
