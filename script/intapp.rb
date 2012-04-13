#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintapps"

opt=ARGV.getopts("afdts")
id,host=ARGV
begin
  aint=IntApps.new.add(id,opt,host)[id]
rescue UserError
  Msg.usage('(-fsd) [id] (host)',
            '-a:client on app',
            '-f:client on frm',
            '-s:server','-d:dummy')
end
sleep if opt["s"]
aint.shell{|cmd|
  aint.exe(cmd)||aint
}

