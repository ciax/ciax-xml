#!/usr/bin/ruby
require "libfield"
require "libfrmcmd"
require "libfrmdb"

dev,*cmd=ARGV
begin
  fdb=FrmDb.new(dev)
  st=Field.new
  if ! STDIN.tty? && str=STDIN.gets(nil)
    st.update_j(str)
  end
  c=FrmCmd.new(fdb,st)
  print c.getframe(cmd)
rescue UserError
  abort "Usage: frmcmd [dev] [cmd] (par) < statfile \n#{$!}"
end
