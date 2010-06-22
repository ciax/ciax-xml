#!/usr/bin/ruby
require "libobjsrv"
require "libiocmd"

warn "Usage: objserver [obj]" if ARGV.size < 1

obj=ARGV.shift
odb=ObjSrv.new(obj)
srv=IoCmd.new(odb['server'],"server_#{obj}")
odb.auto_update('upd',10)

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
