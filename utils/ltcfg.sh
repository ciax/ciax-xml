#!/bin/bash
ltf=~/db/DB-ltx.csv
rsf=~/db/DB-rs.csv
[ "$1" ] || { echo "Usage:ltcfg (-s) [host] (range)"; exit; }
[ "$1" = '-s' ] && { exe="nc";shift; }
host=$1;range=$2
IFS=,
inrange(){
    [ "$range" ] || return 0
    for i in $range; do
        [ ${i%-*} -le $1 ] && [ ${i#*-} -ge $1 ] && return 0
    done
    return 1
}

egrep "^$1" $ltf|while read line; do
    set - $line
    p=$2 dev=$3
    inrange $p || continue
    set - `egrep "^($dev)," $rsf`
    echo "define port $p speed $5"
    echo "define port $p character $6"
    echo "define port $p parity $7"
    echo "define port $p stop $8"
    echo "define port $p flow $9"
    echo "define service rs_$p tcpport 400$p"
    echo "define service rs_$p binary en"
    echo "define service rs_$p port $p en"
    echo "defilne port $p dedicated service rs_$p"
done
echo "initialize server delay 0"