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
  line=Readline.readline(cdb.prompt,true)
  case line
  when /^q/
    break
  when ''
    line='stat'
  end
  puts cdb.dispatch(line){|s| s}
}

