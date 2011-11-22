#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmint"
require "libappsv"

opt=ARGV.getopts("sc")
id,*iocmd=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-sc) [id] ("iocmd")'
  Msg.exit
end
fdb=adb.cover_frm
fobj=FrmInt.new(fdb,opt['c'] ? nil : iocmd)
aobj=AppSv.new(adb,fobj)
if opt["s"]
  require 'libserver'
  Server.new(adb["port"].to_i,aobj.prompt){|cmd|
    aobj.exe(cmd)
  }
else
  require 'libshell'
  Shell.new(aobj.prompt,aobj.commands){|cmd|
    aobj.exe(cmd)||aobj
  }
end
