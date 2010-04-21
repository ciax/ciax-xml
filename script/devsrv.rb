#!/usr/bin/ruby
require "libdevctrl"
require "libdevstat"
require "libxmldoc"
require "libstatio"
include StatIo
IoCmd="exio"

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

while(line=gets.chomp)
  cmd,par=line.split(' ')
  begin
    dc.node_with_id!(cmd)
  rescue
    puts $!
    next
  end
  begin 
    ds.node_with_id!(cmd)
  rescue
    open("|#{IoCmd} #{dev} #{cmd}",'w') do |f|
      dc.devctrl(par) do |ecmd|
        f.puts ecmd
      end
    end
    puts $!
    next
  else
    open("|#{IoCmd} #{dev} #{cmd}",'r+') do |f|
      dc.devctrl(par) do |ecmd|
        f.puts ecmd
      end
      estat=f.gets(nil)
      stat=ds.devstat(estat)
      dc.set_var!(stat)
      p stat
    end
  end
end
