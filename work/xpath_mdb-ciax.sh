#!/bin/bash
#alias xp
if [ "$1" ] ; then
#xpath -e "//item[.//@site='crt' and .//@var='cps'][../../group/@id='g_rot']" mdb-ciax.xml
xpath -e "//group[@id='g_$1']//item[.//@var='cps']" ~/ciax-xml/mdb-ciax.xml
else
cat <<EOF
exchg  : Exchange Commands (0)
select : Select Commands (0)
mvi    : Sequential Instrument Moving Commands (1)
sfr    : Sequential Free Run Commands (1)
atdt   : Sequential Attach/Detach Commands (1)
cer    : Compound Exclusive Run Commands (2)
ctrp   : Compound Transport Commands (2)
cdh    : Compound Run Commands (2)
cfljh  : Compound Flange Jack/Hook Commands (2)
cmov   : Compound Movable Flange Commands (2)
jak    : Atomic Jack Bolt Commands (3)
rot    : Atomic Flange Rotation Commands (3)
mov    : Atomic Movable Flange Commands (3)
cart   : Atomic Cart Commands (3)
assign : Atomic Config Commands (3)
EOF
fi
