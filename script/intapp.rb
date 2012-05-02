#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libapplist"

$opt=ARGV.getopts("afdts")
id,$opt['h']=ARGV
begin
  aint=AppList.new
rescue UserError
  Msg.usage('(-fsd) [id] (host)',
            '-a:client on app',
            '-f:client on frm',
            '-s:server','-d:dummy')
end
sleep if $opt["s"]
cl=Msg::CmdList.new("Change Device",2)
cl.update({'crt' => "cart",'dsi' => "IR stand-by",'dso' => "OPT stand-by"})
loop{
  int=aint[id]
  int.cmdlist['dev']=cl
  id=int.shell||break
}
