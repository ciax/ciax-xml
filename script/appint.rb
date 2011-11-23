#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libappints"

opt=ARGV.getopts("scf")
id,*par=ARGV
par=par.first if opt["c"]
begin
  aint=AppInts.new(par)[id]
rescue
  warn 'Usage: appint (-scf) [id] (host|iocmd)'
  Msg.exit
end
if opt["s"]
  require 'libserver'
  Server.new(aint.port,aint.prompt){|cmd|
    aint.exe(cmd)
  }
else
  require 'libshell'
  Shell.new(aint.prompt,aint.commands){|cmd|
    aint.exe(cmd)||aint
  }
end
