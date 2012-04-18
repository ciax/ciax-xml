#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libhexpack"
require "libintapps"

$opt=ARGV.getopts("s")
id,$opt['h']=ARGV
ARGV.clear
begin
  aint=IntApps.new[id]
rescue UserError
  Msg.usage("(-s) [id] (host)","-s:server")
end
aint.extend(HexPack).init
if $opt["s"]
  aint.server('hexpack',1000){ aint.to_s }
  sleep
else
  aint.shell
end
