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
prt=Print.new(adb,aobj.view)
mode='view'
if opt["s"]
  require 'libserver'
  Server.new(adb["port"].to_i,aobj.prompt){|cmd|
    aobj.upd(cmd).message
  }
else
  require 'libshell'
  Shell.new(aobj.prompt){|cmd|
    case cmd[0]
    when 'view','stat','watch'
      mode=cmd[0]
      cmd.clear
    end
    if msg=aobj.upd(cmd).message
      msg
    else
      case mode
      when 'view'
        prt
      when 'stat'
        Msg.view_struct(aobj.view['stat'],'stat')
      when 'watch'
        aobj.watch
      end
    end
  }
end
