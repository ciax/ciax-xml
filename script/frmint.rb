#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmints"

opt=ARGV.getopts("sc")
id,*par=ARGV
par=par.first if opt["c"]
begin
  f=FrmInts.new.add(id,par)[id]
rescue
  warn "Usage: frmint (-sc) [id] (host|iocmd)"
  Msg.exit
end

if opt["s"]
  require 'libserver'
  Server.new(f.port.to_i-1000,"#{id}>"){|line|
    f.exe(line)
  }
else
  require 'libshell'
  Shell.new(f.prompt,f.commands){|line|
    f.exe(line)||f
  }
end
