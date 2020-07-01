#!/usr/bin/env bash
sort ~/.var/log/{event,input_app,server_site}*_${1:-mix}_2020.log |\
tail -1500|\
EXCLUDE=id,format_ver,data_ver,host,comerr,ioerr,auto,pri,msg,act_time,upd_next,block,int \
json_logview| grep --color=auto -e '$' -e macro
