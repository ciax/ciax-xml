#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libappobj"

opt=ARGV.getopts("sc")
id,*iocmd=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-sc) [id] ("iocmd")'
  Msg.exit
end
fdb=adb.cover_frm
if opt['c']
  require "libfrmcl"
  fobj=FrmCl.new(fdb)
else
  require "libfrmobj"
  fobj=FrmObj.new(fdb,iocmd)
end
aobj=AppObj.new(adb,fobj)
if opt["s"]
  require 'libserver'
  Server.new(adb["port"].to_i,aobj.prompt){|cmd|
    aobj.upd(cmd).message
  }
else
  require 'libshell'
  Shell.new(aobj.prompt,aobj.commands){|cmd|
    aobj.upd(cmd).message||aobj
  }
end
