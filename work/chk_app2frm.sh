#!/usr/bin/env bash
sort ~/.var/log/{input_app,input_frm,field,stream}*_${1:-cci}_2020.log |\
EXCLUDE=id,format_ver,data_ver,host,comerr \
json_logview|\
tail -500|\
egrep --color=auto -e '$' -e '[^"]*on' -e '[^"]*off'
