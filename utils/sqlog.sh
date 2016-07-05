#!/bin/bash
[ "$1" ] || {
    echo "Usage: ${0##*/} [site]"
    var-sites sqlog
    exit
}
sqlite3 ~/.var/log/sqlog_$1.sq3
