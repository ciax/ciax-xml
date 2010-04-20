#!/usr/bin/ruby
require "libdevctrl"
require "libdevstat"
require "libxmldoc"
require "libstatio"
include StatIo

warn "Usage: devsrv [dev]" if ARGV.size < 1

dev=ARGV.shift
begin
  ddb=XmlDoc.new('ddb',dev)
  dc=DevCtrl.new(ddb)
  ds=DevStat.new(ddb)
rescue RuntimeError
  puts $!
  exit 1
end

while(cmd=gets.chomp)
  begin
    dc.node_with_id!(cmd)
    p dc.devctrl
    ds.node_with_id!(cmd)
  rescue
    puts $!
    next
  else
    stat=ds.devstat(read_frame(dev,cmd))
    dc.set_var!(stat)
    p stat
  end
end
