#!/usr/bin/ruby
require "libstat"
require "libfrmcmd"
require "libxmldoc"

warn "Usage: frmcmd [dev] [id] [cmd] (par)" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
cmd=ARGV
begin
  doc=XmlDoc.new('fdb',dev)
  st=Stat.new(id,"field")
  c=FrmCmd.new(doc,st)
  c.setcmd(cmd)
  print c.getframe
rescue RuntimeError
  abort $!.to_s
end
