#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libhexpack"
require "libintapps"

opt=ARGV.getopts("sc")
id,host=ARGV
ARGV.clear
begin
  aint=IntApps.new.add(id,opt,host)[id]
rescue UserError
  Msg.usage("(-sc) [id] (host)")
end
hp=HexPack.new(aint.view,aint.prompt)
if opt["s"]
  require 'libserver'
  Server.new('hexpack',aint.port.to_i+1000){|line|
    aint.exe(line)
    hp
  }.join
else
  require 'libshell'
  Shell.new(aint.prompt){|line|
    aint.exe(line)||hp
  }
end
