#!/usr/bin/bash
sort ~/.var/log/{input_app,server_site}*_${1:-mix}_2020.log |\
tail -1500|\
EXCLUDE=id,format_ver,data_ver,host,comerr,ioerr,auto,pri,msg json_logview
