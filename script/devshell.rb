#!/usr/bin/ruby
require "libdev"

warn "Usage: devshell [dev] [iocmd]" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
ddb=DevCom.new(dev,iocmd)

loop{
  print "#{dev}>"
  cmd,par=gets.chomp.split(' ')
  case cmd
  when /^q/
    break
  when /[\w]+/
    begin
      ddb.setcmd(cmd,par)
      ddb.devcom
    rescue
      puts $!
    end
  else
    p ddb.field
  end
}
