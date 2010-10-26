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
oc=ObjCmd.new(id)
os=ObjStat.new(id)
cdb=ClsSrv.new(cls,id,iocmd){|c| oc.alias(c)}

loop {
  stm=Readline.readline(cdb.prompt,true).split(' ')
  break if /^q/ === stm.first
  begin
    puts cdb.dispatch(stm) || view(os.get_stat(cdb.stat))
  rescue RuntimeError
    puts $!.to_s
  rescue
    puts $!.to_s+$@.to_s
  end
}
