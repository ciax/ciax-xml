#!/bin/bash
# Gen2 Boot up levels
[ -d ~/gen2 ] || { echo "NO OSS files"; exit; }
ln -sf $HOME/gen2/conf/bashrc ~/bin/rc.bash.gen2
PYTHONPATH=~/gen2/share/Git/python
ln -sf $PYTHONPATH/Gen2/client/g2cmd.py ~/bin/OSST_ciaxTSCcommand
ln -sf $PYTHONPATH/SOSS/status/screenPrint.py ~/bin/OSSC_screenPrint
