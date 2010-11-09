#!/usr/bin/ruby
require "libobjcmd"
require "libobjstat"
require "libcls"
require "libmodview"
require "readline"
include ModView

warn "Usage: objshell [cls] [obj] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
obj=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
oc=ObjCmd.new(obj)
os=ObjStat.new(obj)
cdb=Cls.new(cls,id,iocmd)

loop {
  begin
    stm=Readline.readline(cdb.prompt,true).split(' ')
    break if /^q/ === stm.first
    puts cdb.dispatch(stm){|c| oc.alias(c)} || view(os.get_stat(cdb.stat))
  rescue Interrupt
    puts "STOP"
  rescue RuntimeError
    puts $!.to_s
  rescue
    puts $!.to_s+$@.to_s
  end
}
