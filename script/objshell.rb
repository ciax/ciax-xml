#!/usr/bin/ruby
require "libobj"
require "libclssrv"
require "libmodview"
require "readline"
include ModView

warn "Usage: objshell [cls] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
cdb=ClsSrv.new(cls,id,iocmd)
odb=Obj.new(id)

loop {
  stm=Readline.readline(cdb.prompt,true).split(' ')
  stm=['stat'] if stm.empty?
  break if /^q/ === stm.first
  puts cdb.dispatch(stm){|s| view(odb.get_stat(s))}
}
