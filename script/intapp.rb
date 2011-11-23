#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintapps"

opt=ARGV.getopts("sc")
id,*par=ARGV
par=par.first if opt["c"]
begin
  aint=IntApps.new(par)[id]
rescue UserError
  warn 'Usage: intapp (-sc) [id] (host|iocmd)'
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
