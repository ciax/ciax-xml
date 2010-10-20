#!/usr/bin/ruby
require "libstat"
require "libdevrsp"
require "libxmldoc"

abort "Usage: devstat [device] [id] < logline" if ARGV.size < 2
dev=ARGV.shift
id=ARGV.shift
ARGV.clear

ary=gets.split("\t")
time=Time.at(ary.shift.to_f)
stm=ary.shift.split(':')
abort ("Logline:Not response") unless /rcv/ === stm.shift
begin
  ddb=XmlDoc.new('ddb',dev)
  st=Stat.new("field_#{id}")
  r=DevRsp.new(ddb,st)
  r.setrsp(stm)
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump r.getfield(time){ eval(ary.shift) }
st.save_all
