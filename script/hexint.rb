#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libappcl"
require "libhexpack"

opt=ARGV.getopts("s")
id=ARGV.shift
host=ARGV.shift
begin
  adb=InsDb.new(id).cover_app
  ac=AppCl.new(adb,host)
rescue
  warn "Usage: hexint (-s) [id] (host)"
  Msg.exit
end
hp=HexPack.new(ac.view,ac.prompt)
if opt["s"]
  require 'libserver'
  Server.new(ac.port.to_i+1000){|line|
    ac.exe(line)
    hp
  }
else
  require 'libshell'
  Shell.new(ac.prompt){|line|
    ac.exe(line)||hp
  }
end
