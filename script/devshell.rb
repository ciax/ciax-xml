#!/usr/bin/ruby
require "libdev"
require "readline"

warn "Usage: devshell [dev] [id] [iocmd]" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
ddb=Dev.new(dev,id,iocmd)

loop{
  stm=Readline.readline("#{dev}>",true).chomp.split(" ")
  break if /^q/ === stm.first
  begin
    puts ddb.transaction(stm) || ddb.field
  rescue RuntimeError
    puts $!
  rescue
    puts $!.to_s+$@.to_s
  end
}
