#!/usr/bin/ruby
require "libfrm"
require "readline"

warn "Usage: frmshell [dev] [id] [iocmd]" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
fdb=Frm.new(dev,id,iocmd)

loop{
  stm=Readline.readline("#{dev}>",true).chomp.split(" ")
  break if /^q/ === stm.first
  begin
    puts fdb.transaction(stm) || fdb.field
  rescue SelectID
    puts $!.to_s
    puts "== Shell Command =="
    puts " q         : Quit"
  rescue RuntimeError
    puts $!.to_s
  end
}
