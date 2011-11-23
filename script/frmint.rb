#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmints"

opt=ARGV.getopts("sc")
id,*par=ARGV
fint=FrmInts.new
begin
  if opt["c"]
    f=fint.add(id,par.first)[id]
  else
    f=fint.add(id,par)[id]
  end
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
