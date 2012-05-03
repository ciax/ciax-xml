#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libapplist"

$opt=ARGV.getopts("afdts")
id,$opt['h']=ARGV
begin
  aint=AppList.new{|int|
    devs={'crt' => "cart",'dsi' => "IR stand-by",'dso' => "OPT stand-by"}
    int.cmdlist.add_group('dev',"Change Device",devs,2)
  }
  sleep if $opt["s"]
  loop{
    int=aint[id]
    id=int.shell||break
  }
rescue UserError
  Msg.usage('(-fsd) [id] (host)',
            '-a:client on app',
            '-f:client on frm',
            '-s:server','-d:dummy')
end
