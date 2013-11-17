## Install required (Debian squeeze) ##
 ruby1.9.1 (for using JSON)
 libxml-ruby1.9.1 (XML instead of REXML)
 libxml2-utils (xmllint)
 socat
 libsqlite3-ruby1.9.1
 libxml-xpath-perl (xpath command)
 coreutils:
  grep,cut,tail

## Required Apps
xmllint: XML validator
socat: communication for UDP/TCP/..., that has more features than 'nc'
salite3: light weight sql server for logging, not for access from multiple processes  

## ENV Var ##
 RUBYLIB
 XMLPATH
 PROJ
 NOCACHE
 NOSQL

## Dir
~/.var/cache
~/.var/json

## Verbose mode ##
 set VER environment
 VER=string1,string2... for set sum
 VER=string1:strint2..  for set intersection
 VER=* for All

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
  set PROJ to limit Device ID (is in idb-{PROJ}.xml)

## Source comment legend
 #@ : instance variable list
  @< : parent's var (< is added as the number of ancestor generaton) 
       parenthetic var is not used in the class
       * is added for exported var

## Naming rule
 # general
  - method name is recommended to be long word which contains under bar to privent mixing up with local var (verb_noun)
  - local var name is recommended to use abbrev word (as short as possible < 4 letter) 
    (i.e. i,j,k,idx,grp,key(k),hsh(h),ary(a),val(v)...) 
  - DB key which contains Hash or Array will be Symbol. Other keys are String.
  - Status key which could be written out to a file will be String.
 #local var
   args: Command(Array) [cmd,par,par...]
   cid: Command ID(String) "cmd:par:par"
   bat: Batch Array of Commands(Array of Array) [args,args,...]
   f*: Associated with Frm (i.e. fargs, fstat ..)
   a*: Associated with App (i.e. aargs, astat ..)
 #block rerutn value
   set return value to local var 'res' at the end of block if it is expressly provided
