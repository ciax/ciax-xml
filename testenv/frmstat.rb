#!/usr/bin/ruby
require "json"
require "libfrmrsp"
require "libfrmdb"

dev=ARGV.shift
ARGV.clear

begin
  fdb=FrmDb.new(dev)
  field={}
  r=FrmRsp.new(fdb,field)
  str=gets(nil) || exit
  ary=str.split("\t")
  time=Time.at(ary.shift.to_f)
  stm=ary.shift.split(':')
  abort ("Logline:Not response") unless /rcv/ === stm.shift
  r.setrsp(stm){[time,eval(ary.shift)]}
  puts JSON.dump(field)
rescue RuntimeError
  abort "Usage: frmstat [frame] < logline\n#{$!}"
end

