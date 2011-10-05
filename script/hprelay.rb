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
  idb=InsDb.new(id)
rescue
  warn "Usage: hprelay (-s) [id] (host)"
  Msg.exit
end
cli=Client.new(idb,host)

hp=HexPack.new(cli.view,cli.prompt)
port=opt["s"] ? idb['port'].to_i+1000 : nil

Interact.new([],port){|line|
  break unless line
  cli.upd(line)
  hp.upd
}
