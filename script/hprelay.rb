#!/usr/bin/ruby
require "optparse"
require "json"
require "libobjdb"
require "libfield"
require "libiocmd"
require "libhexpack"
require "libinteract"
require "open-uri"

opt={}
OptionParser.new{|op|
  op.on('-s'){|v| opt[:s]=v}
  op.parse!(ARGV)
}
id=ARGV.shift
host=ARGV.shift||'localhost'
url="http://#{host}/json/status_#{id}.json"
begin
  odb=ObjDb.new(id)
  port=odb['port']
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
  open(url){|f|
   @hp.upd(JSON.load(f.read)['stat'])
  }
  @io.snd(line.empty? ? 'stat' : line)
  time,str=@io.rcv
  @hp.issue(str.include?("*"))
}
