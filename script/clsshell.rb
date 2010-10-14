#!/usr/bin/ruby
require "libclssrv"
require "libmodview"
require "readline"

warn "Usage: clsshell [cls] [iocmd] (obj)" if ARGV.size < 1

cls=ARGV.shift
iocmd=ARGV.shift
obj=ARGV.shift||cls
cdb=ClsSrv.new(cls,iocmd,obj)

loop {
  stm=Readline.readline(cdb.prompt,true).split(' ')
  stm=['stat'] if stm.empty?
  break if /^q/ === stm.first
  puts cdb.dispatch(stm){|s| s}
}

