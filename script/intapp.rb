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
modes={'frm' => "Frm mode",'app' => "App mode"}
id='app'
loop{
  case id
  when 'app'
    id=aint.shell(modes)
  when 'frm'
    id=aint.fint.shell(modes)
  else
    break
  end
}
