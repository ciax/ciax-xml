#!/usr/bin/ruby
require "libstat"
require "libfrmcmd"
require "libfrmdb"
require "libcache"

dev,*cmd=ARGV
begin
  fdb=Cache.new("fdb_#{dev}"){FrmDb.new(dev)}
  st=Stat.new
  c=FrmCmd.new(fdb,st)
  c.setcmd(cmd)
  if ! STDIN.tty? && str=STDIN.gets(nil)
    st.update_j(str)
  end
  print c.getframe
rescue UserError
  abort "Usage: frmcmd [dev] [cmd] (par) < statfile \n#{$!}"
end
