#!/usr/bin/ruby
require "libobjsrv"
require "libiocmd"

warn "Usage: objserver [obj]" if ARGV.size < 1

obj=ARGV.shift

sv=ObjSrv.new(obj)
server=sv['server']
srv=IoCmd.new(server,"server_#{obj}",0,nil)
warn server
sv.auto_update

while line=srv.rcv
  line.chomp!
  case line
  when ''
    srv.snd(sv.stat.inspect+"\n")
  else
    srv.snd(sv.session(line))
  end
  srv.snd("#{obj}>")
end
