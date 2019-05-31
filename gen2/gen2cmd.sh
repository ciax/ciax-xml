#!/bin/bash
source gen2mkcmd
par="$(selcmd $*)"
# Background run is judged with last letter (0->BG, others->FG)
[[ "$par" =~ 0$ ]] && opt=-b
gen2exe $opt g2cmd "$par"
