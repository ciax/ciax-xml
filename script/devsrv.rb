#!/usr/bin/ruby
require "libdev"
require "libstatio"
include StatIo

warn "Usage: devsrv [dev] (iocmd)" if ARGV.size < 1

dev=ARGV.shift
iocmd=ARGV.shift || "exio #{dev}"
ddb=Dev.new(dev,iocmd)

loop do 
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    cmd,par=line.split(' ')
    ddb.devcom(cmd,par)
  else
    p ddb.stat
  end
end
