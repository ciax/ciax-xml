#!/bin/bash
source gen2env
source gen2mkcmd
gen2exe ${g2cmd:-g2cmd} $(selcmd $*)
