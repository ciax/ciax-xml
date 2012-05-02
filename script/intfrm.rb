#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmlist"

$opt=ARGV.getopts("fds")
id,$opt['h']=ARGV
begin
  fint=FrmList.new[id]
rescue UserError
  Msg.usage("(-sfd) [id] (host)","-s:server","-f:client","-d:dummy")
end
sleep if $opt["s"]
fint.shell
