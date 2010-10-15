#!/usr/bin/ruby
require "libdev"
require "readline"

warn "Usage: devshell [dev] [id] [iocmd]" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
ddb=DevCom.new(dev,id,iocmd)

loop{
  stm=Readline.readline("#{dev}>",true).chomp.split(" ")
  case stm.first
  when /^q/
    break
  when /[\w]+/
    begin
      puts ddb.devcom(stm)
    rescue
      puts $!
    end
  else
    p ddb.field
  end
}
