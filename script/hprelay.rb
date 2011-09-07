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
  case line
  when nil
    break
  when ''
    open(url){|f|
      json=JSON.load(f.read)
    }
    @hp.upd(json['stat'])
  else
    @hp.issue
    @io.snd(line)
    time,str=@io.rcv
  end
  @hp
}
