#!/usr/bin/ruby
require "libstat"
require "libfrmcmd"
require "libfrmdb"

dev,*cmd=ARGV
begin
  fdb=FrmDb.new(dev)
  st=Stat.new
  if ! STDIN.tty? && str=STDIN.gets(nil)
    st.update_j(str)
  end
  c=FrmCmd.new(fdb,st)
  print c.getframe(cmd)
rescue UserError
  abort "Usage: frmcmd [dev] [cmd] (par) < statfile \n#{$!}"
end
