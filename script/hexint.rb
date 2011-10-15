#!/usr/bin/ruby
require "optparse"
require "libclient"
require "libinsdb"
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
cli=Client.new(id,adb['port'],host)
hp=HexPack.new(cli.view)
port=opt["s"] ? adb['port'].to_i+1000 : nil
Interact.new('',port){|cmd|
  hp.upd(cli.upd(cmd).prompt)
}
