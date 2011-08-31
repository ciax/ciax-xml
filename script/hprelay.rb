#!/usr/bin/ruby
require "json"
require "libfield"
require "libiocmd"
require "libhexpack"
require "libinteract"

id,iocmd,port=ARGV

begin
  @stat=Field.new
  @io=IoCmd.new(iocmd)
  @ap=AscPck.new(id,@stat)
rescue SelectID
  abort "Usage: hprelay [obj] [iocmd] (port)\n#{$!}"
end
prom=['>']
Interact.new(prom,port){|line|
  case line
  when nil
    break
  when ''
    line='stat'
  else
    @ap.issue
  end
  @io.snd(line)
  time,str=@io.rcv
  json,prom[0]=str.split("\n")
  begin
    view=JSON.load(json)
    @stat.update(view['stat'])
  rescue
  end
  @ap.upd
}
