#!/usr/bin/ruby
require "json"
require "libstat"
require "libfrmrsp"
require "libxmldoc"

dev=ARGV.shift
id=ARGV.shift
ARGV.clear

begin
  doc=XmlDoc.new('fdb',dev)
  ary=gets.split("\t")
  time=Time.at(ary.shift.to_f)
  stm=ary.shift.split(':')
  abort ("Logline:Not response") unless /rcv/ === stm.shift
  st=Stat.new(id,"field")
  r=FrmRsp.new(doc,st)
  r.setrsp(stm)
rescue RuntimeError
  abort "Usage: frmstat [frame] [id] < logline\n#{$!}"
end
print JSON.dump r.getfield(time){ eval(ary.shift) }
st.save
