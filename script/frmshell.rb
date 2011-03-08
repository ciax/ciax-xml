#!/usr/bin/ruby
require "libshell"
require "libfrm"

warn "Usage: frmshell [dev] [id] [iocmd] (filter)" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
sh=Shell.new(ARGV.shift)
fdb=Frm.new(dev,id,iocmd)

loop{
  stm=sh.input("#{dev}>"){}.chomp.split(" ")
  break if /^q/ === stm.first
  begin
    puts fdb.transaction(stm) || sh.filter(JSON.dump(fdb.field))
  rescue SelectID
    puts $!.to_s
    puts "== Shell Command =="
    puts " q         : Quit"
  rescue RuntimeError
    puts $!.to_s
  end
}
