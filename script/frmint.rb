#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmint"

opt=ARGV.getopts("sc")
id,*iocmd=ARGV
begin
  fdb=InsDb.new(id).cover_app.cover_frm
rescue
  warn "Usage: frmint (-sc) [id] (host|iocmd)"
  Msg.exit
end
par=opt["c"] ? iocmd.first : iocmd
fobj=FrmInt.new(fdb,par)
if opt["s"]
  require 'libserver'
  Server.new(fdb["port"].to_i-1000,"#{id}>"){|line|
    fobj.exe(line)
  }
else
  require 'libshell'
  Shell.new(fobj.prompt,fobj.commands){|line|
    fobj.exe(line)||fobj
  }
end
