#!/usr/bin/ruby
require "libobjsrv"
require "libiocmd"

warn "Usage: objserver [obj]" if ARGV.size < 1

obj=ARGV.shift
odb=ObjSrv.new(obj)
srv=IoCmd.new(odb['server'],"server_#{obj}")
odb.dispatch('auto start')

loop{ 
  srv.snd(odb.prompt,['snd'])
  line=srv.rcv(['rcv'])
  line.chomp!
  resp=odb.dispatch(line){|s| s.inspect+"\n" }
  srv.snd(resp,['snd'])
}
