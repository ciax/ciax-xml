# Required packages: ruby-libxml,libxml2-utils,socat,sqlite3

## Install required (Debian squeeze) ##
 ruby2.1 or later (for using JSON)
 ruby-libxml (XML instead of REXML)
 libxml2-utils (xmllint)
 apache(http server) + php
 socat
 libxml-xpath-perl (xpath command)
 coreutils:
  grep,cut,tail

## Required Apps
xmllint: XML validator
socat: communication for UDP/TCP/..., that has more features than 'nc'
sqlite3: light weight sql server for logging, not for access from multiple processes

## ENV Var ##
 RUBYLIB
 PROJ
 NOCACHE
 DEBUG
 VER

## Dir
~/.var/cache
~/.var/json

## Verbose mode ##
 set VER environment
 VER=* for All
 VER=@ show traceback of error
 VER=string,.. for set 'or'
 VER=string:..  for set 'and'
 VER=!string1.. for set 'exclude'

## json udp communicaton ##
 no command:
   "" : (cmdline) -> "[]":(udp comm) -> nil : (App::Intect)
 interrupt:
   ^D : (cmdline) -> nil : (readline) -> "interrupt" : (udp comm)

## Server interference ##
Do not run "intfrm","intapp" and "inthex" simultaneously with option -s.
frmsh (intfrm -t)/ used when running site is different from intapp

## Combination of Server/Clients ##
  =========================================
  Client    App        Frm       Stream
  =========================================
  -         -          Shell     simulation
  -         -          Shell     socat
  -         Shell      -         simulation
  -         Shell      -         socat
  Shell     -          Server    simulation
  Shell     -          Server    socat
  -         Shell(-f)  Server    simulation
  -         Shell(-f)  Server    socat
  Shell     Server     -         simulation
  Shell     Server     -         socat
  Shell     Server(-f) Server    simulation
  Shell     Server(-f) Server    socat


## Action mode in Macro ##
  set ACT environment with number [0-3]
  ==================================
  ACT   Exec    Source   Check   Log
  ==================================
  nil   check   file     -       -
  0     check   file     o       -
  1     simu    file     o       -
  2     exec    remote   o       o

## Project mode
  set ENV['PROJ'] to limit Device ID (is in idb-{ENV['PROJ']}.xml)
