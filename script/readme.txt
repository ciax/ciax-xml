## Install required (Debian squeeze) ##
 ruby1.9.1 (for using JSON)
 libxml-ruby1.9.1 (XML instead of REXML)
 libxml2-utils (xmllint)
 socat
 libsqlite3-ruby1.9.1
 libxml-xpath-perl (xpath command)
 coreutils:
  grep,cut,tail

## Verbose mode ##
 set VER environment
 VER=string1,string2... for set sum
 VER=string1:strint2..  for set intersection
 VER=* for All

## udp communicaton ##
 no command:
   "" : (cmdline) -> "stat":(udp comm) -> "" : (App::Intect)
 interrupt:
   ^D : (cmdline) -> nil : (readline) -> "interrupt" : (udp comm)
  
## Server interference ##
Do not run "intfrm","intapp" and "inthex" simultaneously with option -s
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
  set PROJ to limit Device ID (is in idb-{PROJ}.xml)
