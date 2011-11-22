#!/usr/bin/ruby
require "optparse"
require "libinsdb"

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
  pri=Print.new(adb,aint.view)
  Shell.new(aint.prompt,aint.commands){|cmd|
    aint.exe(cmd)||pri
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
    Shell.new(aint.prompt,aint.commands){|cmd|
      aint.exe(cmd)||aint
    }
  end
end
