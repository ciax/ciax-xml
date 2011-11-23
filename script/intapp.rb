#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintapps"

opt=ARGV.getopts("scd")
id,*par=ARGV
begin
  aint=IntApps.new.add(id,opt,par)[id]
rescue UserError
  warn 'Usage: intapp (-scd) [id] (host|iocmd) # -s:server, -c:client'
  Msg.exit
end
sleep if opt["s"]
require 'libshell'
Shell.new(aint.prompt,aint.commands){|cmd|
  aint.exe(cmd)||aint
}

