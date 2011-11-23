#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libhexpack"
require "libintapps"

opt=ARGV.getopts("sc")
id,*par=ARGV
par=par.first if opt['c']
begin
  aint=IntApps.new(par)[id]
rescue UserError
  warn "Usage: inthex (-sc) [id] (host|iocmd)"
  Msg.exit
end
hp=HexPack.new(aint.view,aint.prompt)
if opt["s"]
  require 'libserver'
  Server.new(adb['port'].to_i+1000){|line|
    aint.exe(line)
    hp
  }.join
else
  require 'libshell'
  Shell.new(aint.prompt){|line|
    aint.exe(line)||hp
  }
end
