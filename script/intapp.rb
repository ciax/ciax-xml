#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintapps"

opt=ARGV.getopts("scd")
id,*cobj=ARGV
begin
  aint=IntApps.new.add(id,opt,cobj)
rescue UserError
  Msg.usage('(-scd) [id] (host)','-s:server, -c:client, -d:dummy')
end
sleep if opt["s"]
require 'libshell'
Shell.new(aint.prompt,aint.commands){|cmd|
  aint.exe(cmd)||aint
}

