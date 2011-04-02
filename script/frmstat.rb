#!/usr/bin/ruby
require "json"
require "libstat"
require "libfrmrsp"
require "libxmldoc"

usage="Usage: frmstat [frame] [id] < logline\n"
dev=ARGV.shift
id=ARGV.shift
ARGV.clear

begin
  doc=XmlDoc.new('fdb',dev,usage)
  ary=gets.split("\t")
  time=Time.at(ary.shift.to_f)
  stm=ary.shift.split(':')
  abort ("Logline:Not response") unless /rcv/ === stm.shift
  st=Stat.new(id,"field")
  r=FrmRsp.new(doc,st)
  r.setrsp(stm)
rescue RuntimeError
  abort $!.to_s
end
print JSON.dump r.getfield(time){ eval(ary.shift) }
st.save
