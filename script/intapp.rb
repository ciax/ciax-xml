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
  begin
  int=aint[id]
  end while id=int.shell
rescue UserError
  Msg.usage('(-fsd) [id] (host)',
            '-a:client on app',
            '-f:client on frm',
            '-s:server','-d:dummy')
end
