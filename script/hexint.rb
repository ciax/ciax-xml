#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libhexpack"

opt=ARGV.getopts("sc")
id,*par=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn "Usage: hexint (-sc) [id] (host|iocmd)"
  Msg.exit
end
if opt['c']
  require "libappcl"
  aint=AppCl.new(adb,par.first)
else
  require "libappsv"
  require "libfrmsv"
  fint=FrmSv.new(adb.cover_frm,par)
  aint=AppSv.new(adb,fint)
end
hp=HexPack.new(aint.view,aint.prompt)
if opt["s"]
  require 'libserver'
  Server.new(adb['port'].to_i+1000){|line|
    aint.exe(line)
    hp
  }
else
  require 'libshell'
  Shell.new(aint.prompt){|line|
    aint.exe(line)||hp
  }
end
