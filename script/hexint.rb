#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libappcl"
require "libhexpack"
require "libinteract"

opt=ARGV.getopts("s")
id=ARGV.shift
host=ARGV.shift||'localhost'
begin
  adb=InsDb.new(id).cover_app
rescue
  warn "Usage: hexint (-s) [id] (host)"
  Msg.exit
end
cli=AppCl.new(adb,host)
hp=HexPack.new(cli.view,cli.prompt)
if opt["s"]
  require 'libserver'
  Server.new(adb["port"].to_i+1000){|line|
    cli.upd(line)
    hp.upd
  }
else
  require 'libshell'
  Shell.new(cli.prompt){|line|
    cli.upd(line).message||hp.upd
  }
end
