#!/usr/bin/ruby
require "libobjsrv"
require "libiocmd"

warn "Usage: objserver [obj]" if ARGV.size < 1

obj=ARGV.shift

odb=ObjSrv.new(obj)
server=odb['server']
srv=IoCmd.new(server,"server_#{obj}",0,nil)
warn server
odb.auto_update

while line=srv.rcv
  line.chomp!
  case line
  when /[\w]+/
    srv.snd(odb.session(line))
  else
    srv.snd(odb.stat.inspect+"\n")
  end
  srv.snd("#{obj}>")
end
