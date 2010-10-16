#!/usr/bin/ruby
require "libclssrv"
require "libmodview"
require "readline"

warn "Usage: clsshell [cls] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
cdb=ClsSrv.new(cls,id,iocmd)

loop {
  stm=Readline.readline(cdb.prompt,true).split(' ')
  stm=['stat'] if stm.empty?
  break if /^q/ === stm.first
  puts cdb.dispatch(stm){|s| s}
}
