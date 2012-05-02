#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libhexpack"
require "libapplist"

$opt=ARGV.getopts("s")
id,$opt['h']=ARGV
ARGV.clear
begin
  aint=AppList.new[id]
rescue UserError
  Msg.usage("(-s) [id] (host)","-s:server")
end
aint.extend(HexPack)
if $opt["s"]
  aint.socket
  sleep
else
  aint.shell
end
