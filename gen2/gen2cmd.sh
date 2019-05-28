#!/bin/bash
source gen2env
source gen2mkcmd
${g2cmd:-g2cmd} $(selcmd $*)
