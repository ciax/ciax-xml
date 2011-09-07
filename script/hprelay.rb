#!/usr/bin/ruby
require "optparse"
require "json"
require "libobjdb"
require "libfield"
require "libiocmd"
require "libhexpack"
require "libinteract"

opt={}
OptionParser.new{|op|
  op.on('-s'){|v| opt[:s]=v}
  op.parse!(ARGV)
}
id=ARGV.shift
host=ARGV.shift||'localhost'

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
prom=['>']
Interact.new(prom,port){|line|
  case line
  when nil
    break
  when ''
    line='stat'
  else
    @hp.issue
  end
  @io.snd(line)
  time,str=@io.rcv
  json,prom[0]=str.split("\n")
  begin
    view=JSON.load(json)
    @stat.update(view['stat'])
  rescue
  end
  @hp.upd(@stat)
}
