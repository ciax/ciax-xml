#!/bin/bash
# Gen2 Boot up levels
if [ -d ~/gen2 ] ; then
    echo "OSS environment"
    ln -sf $HOME/gen2/conf/bashrc ~/bin/rc.bash.gen2
    PYTHONPATH=~/gen2/share/Git/python
    ln -sf $PYTHONPATH/Gen2/client/g2cmd.py ~/bin/g2cmd
    ln -sf $PYTHONPATH/SOSS/status/screenPrint.py ~/bin/g2prt
else
    echo "Simulation environment"
    ln -sf ~/bin/gen2sim ~/bin/g2cmd
    ln -sf ~/bin/gen2sim ~/bin/g2prt
fi
