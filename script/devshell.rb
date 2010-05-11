#!/usr/bin/ruby
require "libdev"

warn "Usage: devshell [dev] [iocmd]" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
ddb=Dev.new(dev,iocmd)

loop do 
  print "#{dev}>"
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



