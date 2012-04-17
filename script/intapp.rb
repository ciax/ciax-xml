#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintapps"

$opt=ARGV.getopts("afdts")
id,$opt['h']=ARGV
begin
  aint=IntApps.new[id]
rescue UserError
  Msg.usage('(-fsd) [id] (host)',
            '-a:client on app',
            '-f:client on frm',
            '-s:server','-d:dummy')
end
sleep if $opt["s"]
aint.shell{|msg| msg||aint}
