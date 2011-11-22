#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmcl"
require "libfrmsv"

opt=ARGV.getopts("sc")
id,*par=ARGV
begin
  fdb=InsDb.new(id).cover_app.cover_frm
rescue
  warn "Usage: frmint (-sc) [id] (host|iocmd)"
  Msg.exit
end
if opt["c"]
  require 'libshell'
  fint=FrmCl.new(fdb,par.first)
  Shell.new(fint.prompt,fint.commands){|line|
    fint.exe(line)||fint
  }
elsif opt["s"]
  require 'libserver'
  fint=FrmSv.new(fdb,par)
  Server.new(fdb["port"].to_i-1000,"#{id}>"){|line|
    fint.exe(line)
  }
else
  require 'libshell'
  fint=FrmSv.new(fdb,par)
  Shell.new(fint.prompt,fint.commands){|line|
    fint.exe(line)||fint
  }
end
