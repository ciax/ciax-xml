#!/usr/bin/ruby
require "libdev"

warn "Usage: devshell [dev] [iocmd]" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
ddb=DevCom.new(dev,iocmd)

loop{
  print "#{dev}>"
  cary=gets.chomp.split(' ')
  case cary[0]
  when /^q/
    break
  when /[\w]+/
    begin
      ddb.setcmd(cary)
      ddb.devcom
    rescue
      puts $!
    end
  else
    p ddb.field
  end
}
