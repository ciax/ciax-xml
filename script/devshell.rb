#!/usr/bin/ruby
require "libdev"
require "readline"

warn "Usage: devshell [dev] [iocmd] (obj)" if ARGV.size < 2

dev=ARGV.shift
iocmd=ARGV.shift
obj=ARGV.shift || dev
ddb=DevCom.new(dev,iocmd,obj)

loop{
  line=Readline.readline("#{dev}>",true).chomp
  case line
  when /^q/
    break
  when /[\w]+/
    begin
      puts ddb.setcmd(line) || ddb.devcom
    rescue
      puts $!
    end
  else
    p ddb.field
  end
}
