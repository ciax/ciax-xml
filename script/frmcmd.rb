#!/usr/bin/ruby
require "libstat"
require "libfrmcmd"
require "libfrmdb"

dev=ARGV.shift
id=ARGV.shift
cmd=ARGV
begin
  fdb=FrmDb.new(dev)
  st=Stat.new(id,"field")
  c=FrmCmd.new(fdb,st)
  c.setcmd(cmd)
  print c.getframe
rescue UserError
  abort "Usage: frmcmd [dev] [id] [cmd] (par)\n#{$!}"
end
