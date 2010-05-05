#!/usr/bin/ruby
require "libdev"
require "libmodfile"
include ModFile

warn "Usage: devsrv [dev] [iocmd]" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
ddb=Dev.new(dev,iocmd)

loop do 
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    cmd,par=line.split(' ')
    save_stat(dev,ddb.devcom(cmd,par))
  else
    p ddb.stat
  end
end



