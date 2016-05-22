#!/bin/bash
cd ~/.var/json
[ "$PROJ" = 'dummy' ] && site=tmc || site=mmc
mmc2cmi < status_$site.json |tee status_cmi.json|tr -d '"'|grep cmi:
