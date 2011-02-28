#!/usr/bin/ruby
require "json"
require "libstat"
require "libfrmrsp"
require "libxmldoc"

abort "Usage: frmstat [device] [id] < logline" if ARGV.size < 2
dev=ARGV.shift
id=ARGV.shift
ARGV.clear

ary=gets.split("\t")
time=Time.at(ary.shift.to_f)
stm=ary.shift.split(':')
abort ("Logline:Not response") unless /rcv/ === stm.shift
begin
  fdb=XmlDoc.new('fdb',dev)
  st=Stat.new(id,"field")
  r=FrmRsp.new(fdb,st)
  r.setrsp(stm)
rescue RuntimeError
  abort $!.to_s
end
print JSON.dump r.getfield(time){ eval(ary.shift) }
st.save
