#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintapps"

opt=ARGV.getopts("saf")
id,*par=ARGV
begin
  aint=IntApps.new.add(id,opt,par)[id]
rescue UserError
  warn 'Usage: intapp (-saf) [id] (host|iocmd)'
  Msg.exit
end
if opt["s"]
  require 'libserver'
  Server.new(aint.port,aint.prompt){|cmd|
    aint.exe(cmd)
  }.join
else
  require 'libshell'
  Shell.new(aint.prompt,aint.commands){|cmd|
    aint.exe(cmd)||aint
  }
end
