#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmsv"
require "libappsv"

opt=ARGV.getopts("s")
id,*iocmd=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-s) [id] (iocmd)'
  Msg.exit
end
fdb=adb.cover_frm
fint=FrmSv.new(fdb,iocmd)
aint=AppSv.new(adb,fint)
if opt["s"]
  require 'libserver'
  Server.new(adb["port"].to_i,aint.prompt){|cmd|
    aint.exe(cmd)
  }
else
  require 'libshell'
  Shell.new(aint.prompt,aint.commands){|cmd|
    aint.exe(cmd)||aint
  }
end
