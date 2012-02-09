#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintapps"

opt=ARGV.getopts("afdts")
id,host=ARGV
begin
  aint=IntApps.new.add(id,opt,host)[id]
rescue UserError
  Msg.usage('(-scfd) [id] (host)','-s:server, -a:client,-f:client on frm, -d:dummy')
end
sleep if opt["s"]
require 'libshell'
Shell.new(aint.prompt,aint.commands){|cmd|
  aint.exe(cmd)||aint
}

