#!/usr/bin/ruby
require "libstat"
require "libfrmcmd"
require "libxmldoc"

usage="Usage: frmcmd [dev] [id] [cmd] (par)\n"

dev=ARGV.shift
id=ARGV.shift
cmd=ARGV
begin
  doc=XmlDoc.new('fdb',dev,usage)
  st=Stat.new(id,"field")
  c=FrmCmd.new(doc,st)
  c.setcmd(cmd)
  print c.getframe
rescue UserError
  abort $!.to_s
end
