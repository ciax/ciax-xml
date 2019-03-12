#!/bin/bash
usage(){
    cat <<-EOF > /dev/stderr
Usage: gen2mkcmd [osscmd]
    login,logout,init,tsconly,tscpri
    ron,roff,jon,joff,jres
    rhook,runhk,rstop
    ajup,ajdw,ajstop
    jup [n],jdw [n],jstop [n]
    setinst [n]
EOF
}
id="$1"
shift
num=$(printf %02d ${1:-1})
case "$id" in
    login) echo "1A1901ciax%%%%%%%%%%%%%%%% CIAX%%%%%%%%%%%% dummyunit dummyMenu dummyMessage";;
    logout) echo "1A1902";;
    init)  echo "1A1011";;
    tsconly) echo "1A1008TSCONLY";;
    tscpri) echo "1A1008TSCPRI%";;
    ron) echo "904013";;
    roff) echo "904014";;
    jon) echo "132001ON%";;
    joff) echo "132001OFF";;
    jres) echo "132008";;
    rhook) echo "-b 132004";;
    runhk) echo "-b 132005";;
    rstop) echo "104011";;
    ajup) echo "-b 932001";;
    ajdw) echo "-b 932002";;
    ajstop) echo "932003";;
    jup) echo "-b 932004$num";;
    jdw) echo "-b 932005$num";;
    jstop) echo "932006$num";;
    setinst) echo "13200700$num";;
    *) usage;;
esac
