#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmobj"

opt=ARGV.getopts("s")
id,*iocmd=ARGV
begin
  fdb=InsDb.new(id).cover_app.cover_frm
rescue
  warn "Usage: frmint (-s) [id] (iocmd)"
  Msg.exit
end
fobj=FrmObj.new(fdb,iocmd)
if opt["s"]
  require 'libserver'
  Server.new(fdb["port"].to_i-1000,"#{id}>"){|line|
    fobj.upd(line).message
  }
else
  require 'libshell'
  Shell.new("#{id}>",fobj.commands){|line|
    fobj.upd(line).message||fobj
  }
end
