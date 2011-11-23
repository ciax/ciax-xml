#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmints"

opt=ARGV.getopts("sc")
id,*par=ARGV
par=par.first if opt["c"]
#begin
  fint=FrmInts.new.add(id,par)[id]
#rescue
#  warn "Usage: frmint (-sc) [id] (host|iocmd)"
#  Msg.exit
#end

if opt["s"]
  require 'libserver'
  Server.new(fint.port.to_i-1000,"#{id}>"){|line|
    fint.exe(line)
  }
else
  require 'libshell'
  Shell.new(fint.prompt,fint.commands){|line|
    fint.exe(line)||fint
  }
end
