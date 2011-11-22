#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libappcl"
require "libhexpack"

opt=ARGV.getopts("s")
id=ARGV.shift
host=ARGV.shift
begin
  cli=AppCl.new(id,host)
rescue
  warn "Usage: hexint (-s) [id] (host)"
  Msg.exit
end
hp=HexPack.new(cli.view,cli.prompt)
if opt["s"]
  require 'libserver'
  Server.new(cli.port.to_i+1000){|line|
    cli.exe(line)
    hp
  }
else
  require 'libshell'
  Shell.new(cli.prompt){|line|
    cli.exe(line)||hp
  }
end
