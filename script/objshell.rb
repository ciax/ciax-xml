#!/usr/bin/ruby
require "libobjcmd"
require "libobjstat"
require "libclssrv"
require "libmodview"
require "readline"
include ModView

warn "Usage: objshell [cls] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
cdb=ClsSrv.new(cls,id,iocmd)
oc=ObjCmd.new(id)
os=ObjStat.new(id)

loop {
  stm=Readline.readline(cdb.prompt,true).split(' ')
  break if /^q/ === stm.first
  puts cdb.dispatch(stm){|c| oc.alias(c)} || view(os.get_stat(cdb.stat))
}
