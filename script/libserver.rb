#!/usr/bin/ruby
require "socket"
require "libmsg"

# block return object should have message()
class Server
  def initialize(prom,port)
    @v=Msg::Ver.new("server",1)
    @v.msg{"Init/Server:#{port}"}
    @v.msg{"Prompt:#{prom.inspect}"}
    UDPSocket.open{ |udp|
      udp.bind("0.0.0.0",port)
      loop {
        select([udp])
        line,addr=udp.recvfrom(4096)
        @v.msg{"Recv:#{line} is #{line.class}"}
        line='' if /^stat/ === line
        cmd=line.chomp.split(' ')
        begin
          msg=yield(cmd).message.to_s
        rescue SelectCMD
          msg="NO CMD\n"
        rescue RuntimeError
          msg="ERROR\n"
          warn msg
        end
        @v.msg{"Send:#{msg},#{prom}"}
        msg << prom
        udp.send(msg,0,addr[2],addr[1])
      }
    }
  end
end
