#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libhexpack"
require "libintapps"

opt=ARGV.getopts("s")
id,host=ARGV
ARGV.clear
begin
  aint=IntApps.new.add(id,opt,host)[id]
rescue UserError
  Msg.usage("(-s) [id] (host)","-s:server")
end
hp=HexPack.new(aint.stat,aint.prompt)
if opt["s"]
  aint.server('hexpack',1000){ hp}.join
else
  aint.shell{|msg| msg||hp}
end
