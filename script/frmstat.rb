#!/usr/bin/ruby
require "json"
require "libfrmrsp"
require "libfrmdb"

dev=ARGV.shift
ARGV.clear

begin
  fdb=FrmDb.new(dev)
  st={}
  r=FrmRsp.new(fdb,st)
  ary=gets.split("\t")
  time=Time.at(ary.shift.to_f)
  stm=ary.shift.split(':')
  abort ("Logline:Not response") unless /rcv/ === stm.shift
  r.setrsp(stm)
  r.getfield(time){ eval(ary.shift) }
warn st
  puts JSON.dump(st)
rescue RuntimeError
  abort "Usage: frmstat [frame] < logline\n#{$!}"
end

