#!/usr/bin/ruby
require "lib0bjsrv"
require "libiocmd"

warn "Usage: objserver [obj]" if ARGV.size < 1

obj=ARGV.shift
odb=ObjSrv.new(obj)
srv=IoCmd.new(odb.server,"server_#{obj}")
#odb.dispatch('auto start')

loop{ 
  line=srv.rcv(['rcv'])
  line.chomp!
  line='stat' if line == ''
  resp=odb.dispatch(line){|s|
    sa=Array.new
    s.each{|k,v|
      sa << "#{k}=\"#{v['val']}\""
    }
    sa.join(",")
  }+"\n"
  srv.snd(resp,['snd'])
  srv.snd(odb.prompt,['snd'])
}
