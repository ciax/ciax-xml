#!/bin/sh
. gen2env
port=${1:-9999}
srv="socat tcp-l:$port,reuseaddr,fork EXEC:'/bin/sh'"
ps -ef|grep -v "grep"|grep -q "$srv" && { echo "Redirecter is already running"; exit; }
echo "Start OSS Redirector at [$port]"
$srv &
