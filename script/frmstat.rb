#!/usr/bin/ruby
require "json"
require "libstat"
require "libfrmrsp"
require "libfrmdb"

dev=ARGV.shift
id=ARGV.shift
ARGV.clear

begin
  fdb=FrmDb.new(dev)
  st=Stat.new(id,"field")
  r=FrmRsp.new(fdb,st)
  ary=gets.split("\t")
  time=Time.at(ary.shift.to_f)
  stm=ary.shift.split(':')
  abort ("Logline:Not response") unless /rcv/ === stm.shift
  r.setrsp(stm)
  r.getfield(time){ eval(ary.shift) }
  st.save
rescue RuntimeError
  abort "Usage: frmstat [frame] [id] < logline\n#{$!}"
end

