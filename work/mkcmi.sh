#!/bin/bash
cd ~/.var/json
mmc2cmi < status_mmc.json |tee status_cmi.json|tr -d '"'|grep cmi:
