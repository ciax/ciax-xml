#!/usr/bin/ruby
require "libdev"

warn "Usage: devsrv [dev] (iocmd)" if ARGV.size < 1

dev=ARGV.shift || 'bbe'
iocmd=ARGV.shift || "nc ltc-i 4003"
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



