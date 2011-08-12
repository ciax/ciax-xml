#!/usr/bin/ruby
require "json"
require "libiocmd"
require "libserver"
require "libascpck"

cls,id,iocmd,port=ARGV
begin
  stat={}
  io=IoCmd.new(iocmd)
  ap=AscPck.new(id,stat)
rescue SelectID
  abort "Usage: aprelay [cls] [id] [iocmd] [port]\n#{$!}"
end
Server.new(port,["\n",">"]){|line|
  if line.empty?
    io.snd(line)
    stat.update(JSON.load(io.rcv))
  else
    io.snd(line)
    ap.issue
    io.rcv
  end
  ap.upd
}
