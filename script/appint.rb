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
prt=Print.new(adb[:status],aobj.view)
if opt["s"]
  require 'libserver'
  Server.new(adb["port"].to_i){|line|
    aobj.upd(line)
  }
else
  require 'libshell'
  Shell.new(aobj.prompt){|line|
    aobj.upd(line).message||prt
  }
end
