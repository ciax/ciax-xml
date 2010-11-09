#!/usr/bin/ruby
require "libcls"
require "readline"

warn "Usage: clsshell [cls] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
cdb=Cls.new(cls,id,iocmd)

loop {
  begin
    stm=Readline.readline(cdb.prompt,true).split(' ')
    break if /^q/ === stm.first
    puts cdb.dispatch(stm){|s|s} || cdb.stat
  rescue Interrupt
    puts "STOP"
  rescue
    puts $!
  end
}
