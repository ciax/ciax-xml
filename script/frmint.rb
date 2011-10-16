#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmobj"
require "libinteract"

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
  Server.new(adb["port"].to_i-1000){|line|
    fobj.upd(line)
  }
else
  require 'libshell'
  Shell.new(aobj.prompt){|line|
    fobj.upd(line).message||fobj.field
  }
end
