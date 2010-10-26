#!/usr/bin/ruby
require "libclssrv"
require "readline"

warn "Usage: clsshell [cls] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
cdb=ClsSrv.new(cls,id,iocmd){|s| s}

loop {
  stm=Readline.readline(cdb.prompt,true).split(' ')
  break if /^q/ === stm.first
  puts cdb.dispatch(stm) || cdb.stat
}
