#!/usr/bin/ruby
require "libclssrv"
require "readline"

warn "Usage: clsshell [cls] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
cdb=ClsSrv.new(cls,id,iocmd)

loop {
  stm=Readline.readline(cdb.prompt,true).split(' ')
  break if /^q/ === stm.first
  begin
    puts cdb.dispatch(stm){|s|s} || cdb.stat
  rescue RuntimeError
    puts $!.to_s
  rescue
    puts $!
  end
}
