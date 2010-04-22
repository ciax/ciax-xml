#!/usr/bin/ruby
require "libdev"
require "libstatio"
include StatIo

warn "Usage: devsrv [dev]" if ARGV.size < 1

dev=ARGV.shift
ddb=Dev.new(dev,"exio #{dev}")

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
