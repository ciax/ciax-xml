#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libhexpack"
require "libapplist"

$opt=ARGV.getopts("s")
id,$opt['h']=ARGV
ARGV.clear
begin
  aint=App::List.new[id]
rescue UserError
  Msg.usage("(-s) [id] (host)","-s:server")
end
aint.extend(HexPack)
if $opt["s"]
  aint.server
  sleep
else
  aint.shell
end
