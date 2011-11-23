#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libmodapp"
require "libfrmints"

opt=ARGV.getopts("scf")
id,*par=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-scf) [id] (host|iocmd)'
  Msg.exit
end
if opt["c"]
  require "libappcl"
  require 'libshell'
  aint=AppCl.new(adb,par.first)
  aint.extend(ModApp).init(adb)
  Shell.new(aint.prompt,aint.commands){|cmd|
    aint.exe(cmd)||aint
  }
else
  par=par.first if opt["f"]
  fint=FrmInts.new.add(id,par)[id]
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
