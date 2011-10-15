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
          msg=yield(cmd).message
        rescue SelectCMD
          msg="NO CMD"
        rescue RuntimeError
          msg="ERROR"
          warn msg
        end
        @v.msg{"Send:#{msg},#{prom}"}
        udp.send([msg,prom].compact.join("\n"),0,addr[2],addr[1])
      }
    }
  end
end
