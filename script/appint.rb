#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libmodapp"

opt=ARGV.getopts("sc")
id,*iocmd=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-sc) [id] (host|iocmd)'
  Msg.exit
end
if opt["c"]
  require "libappcl"
  require "libprint"
  require 'libshell'
  aint=AppCl.new(adb,iocmd.first)
  aint.extend(ModApp).init(adb)
  Shell.new(aint.prompt,aint.commands){|cmd|
    aint.exe(cmd)||aint
  }
else
  require "libfrmsv"
  require "libappsv"
  fint=FrmSv.new(adb.cover_frm,iocmd)
  aint=AppSv.new(adb,fint)
  if opt["s"]
    require 'libserver'
    Server.new(adb["port"].to_i,aint.prompt){|cmd|
      aint.exe(cmd)
    }
  else
    require 'libshell'
    aint.extend(ModApp).init(adb)
    Shell.new(aint.prompt,aint.commands){|cmd|
      aint.exe(cmd)||aint
    }
  end
end
