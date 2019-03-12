#!/bin/sh
port=${1:-19990}
dev=${2:-/dev/ttyUSB0}
echo "Start COMM ($dev) Redirector at [$port]"
sudo socat tcp-l:$port,reuseaddr,fork $dev,raw,b38400 &
