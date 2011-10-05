#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libiocmd"
require "libhexpack"
require "libinteract"
require "liburiview"

begin
  opt=ARGV.getopts("s")
  id=ARGV.shift
  host=ARGV.shift||'localhost'
  view=UriView.new(id,host)
  idb=InsDb.new(id)
  port=idb['port']
  @io=IoCmd.new(["socat","-","udp:#{host}:#{port}"])
  @hp=HexPack.new(id)
rescue
  warn "Usage: hprelay (-s) [id] (host)"
  Msg.exit
end
port=opt["s"] ? port.to_i+1000 : nil
json='{}'
Interact.new([],port){|line|
  break unless line
  @hp.upd(view.upd['stat'])
  @io.snd(line.empty? ? 'stat' : line)
  time,str=@io.rcv
  @hp.issue(str.include?("*"))
}
