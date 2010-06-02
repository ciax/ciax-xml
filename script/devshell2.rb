#!/usr/bin/ruby
require "libdev2"

warn "Usage: devshell [dev] [iocmd]" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
ddb=DevCom.new(dev,iocmd)

loop{
  print "#{dev}>"
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    begin
      ddb.setcmd(line)
      ddb.devcom
    rescue
      puts $!
    end
  else
    p ddb.stat
  end
}



