#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libmodapp"

opt=ARGV.getopts("scf")
id,*iocmd=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-scf) [id] (host|iocmd)'
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
  fdb=adb.cover_frm
  if opt["f"]
    require "libfrmcl"
    fint=FrmCl.new(fdb,iocmd.first)
  else
    require "libfrmsv"
    fint=FrmSv.new(fdb,iocmd)
  end
  require "libappsv"
  aint=AppSv.new(adb,fint)
  if opt["s"]
    require 'libserver'
    Server.new(adb["port"],aint.prompt){|cmd|
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
