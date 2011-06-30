#!/usr/bin/ruby
require "json"
require "libstat"
require "libfrmcmd"
require "libfrmdb"

dev,*cmd=ARGV
begin
  fdb=FrmDb.new(dev)
  st=Stat.new
  c=FrmCmd.new(fdb,st)
  c.setcmd(cmd)
  if ! STDIN.tty? && str=STDIN.gets(nil)
    st.update(JSON.load(str))
  end
  print c.getframe
rescue UserError
  abort "Usage: frmcmd [dev] [cmd] (par) < statfile \n#{$!}"
end
