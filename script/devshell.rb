#!/usr/bin/ruby
require "libdev"
require "readline"

warn "Usage: devshell [dev] [iocmd] (obj)" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
obj=ARGV.shift || dev
ddb=DevCom.new(dev,iocmd,obj)

loop{
  statement=Readline.readline("#{dev}>",true).chomp.split(" ")
  case statement.first
  when /^q/
    break
  when /[\w]+/
    begin
      puts ddb.devcom(statement)
    rescue
      puts $!
    end
  else
    p ddb.field
  end
}
