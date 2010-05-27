#!/usr/bin/ruby
require "libdev"

warn "Usage: devshell [dev] [iocmd]" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
ddb=Dev.new(dev,iocmd)

loop{
  print "#{dev}>"
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    begin
      ddb.devcom(line)
    rescue
      puts $!
      puts $@
    end
  else
    p ddb.stat
  end
}



