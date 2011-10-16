#!/usr/bin/ruby
require "libmsg"
require "socket"

class Server
  def initialize(port)
    @v=Msg::Ver.new("server",1)
    @v.msg{"Init/Server:#{port}"}
    UDPSocket.open{ |udp|
      udp.bind("0.0.0.0",port)
      loop {
        select([udp])
        line,addr=udp.recvfrom(4096)
        @v.msg{"Recv:#{line} is #{line.class}"}
        line='' if /^stat/ === line
        cmd=line.chomp.split(' ')
        begin
          msg=yield(cmd)
        rescue SelectCMD
          msg="NO CMD"
        rescue RuntimeError
          msg="ERROR"
          warn msg
        end
        @v.msg{"Send:#{msg}"}
        udp.send(msg.to_s,0,addr[2],addr[1])
      }
    }
  end
end
