#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libapplist"

$opt=ARGV.getopts("afdts")
id,$opt['h']=ARGV
begin
  aint=App::List.new{|int,devs|
    int.cmdlist.add_group('dev',"Change Device",devs)
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
