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
sleep if opt["s"]
require 'libshell'
Shell.new(aint.prompt,aint.commands){|cmd|
  aint.exe(cmd)||aint
}

