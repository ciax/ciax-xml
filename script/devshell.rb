#!/usr/bin/ruby
require "libdev"
require "readline"

warn "Usage: devshell [dev] [iocmd]" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
ddb=DevCom.new(dev,iocmd)

loop{
  cary=Readline.readline("#{dev}>",true).chomp.split(' ')
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
