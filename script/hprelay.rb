#!/usr/bin/ruby
require "optparse"
require "libentdb"
require "libfield"
require "libiocmd"
require "libhexpack"
require "libinteract"
require "liburiview"

opt={}
OptionParser.new{|op|
  op.on('-s'){|v| opt[:s]=v}
  op.parse!(ARGV)
}
id=ARGV.shift
host=ARGV.shift||'localhost'
view=UriView.new(id,host)
begin
  edb=EntDb.new(id)
  port=edb['port']
  @io=IoCmd.new("socat - udp:#{host}:#{port}")
  @stat=Field.new
  @hp=HexPack.new(id)
rescue SelectID
  abort "Usage: hprelay (-s) [id] (host)\n#{$!}"
end
port=opt[:s] ? port.to_i+1000 : nil
json='{}'
Interact.new([],port){|line|
  break unless line
  @hp.upd(view.upd['stat'])
  @io.snd(line.empty? ? 'stat' : line)
  time,str=@io.rcv
  @hp.issue(str.include?("*"))
}
