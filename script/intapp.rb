#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libapplist"

$opt=ARGV.getopts("afdts")
id,$opt['h']=ARGV
begin
  aint=App::List.new
  begin
  int=aint[id]
  sleep if $opt["s"]
  end while id=int.shell
rescue UserError
  Msg.usage('(-fsd) [id] (host)',
            '-a:client on app',
            '-f:client on frm',
            '-s:server','-d:dummy')
end
