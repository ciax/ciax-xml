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
    if line=Readline.readline(cdb.prompt,true)
      break if /^q/ === line
      puts cdb.dispatch(line.split(' ')){|s|s} || cdb.stat
    else
      puts cdb.interrupt
    end
  rescue RuntimeError
    puts $!.to_s
  rescue
    puts $!.to_s+$@.to_s
  end
}
