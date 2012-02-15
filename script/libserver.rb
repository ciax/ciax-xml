#!/usr/bin/ruby
require "libmsg"
require "socket"

class Server < Thread
  def initialize(type,port,prompt=nil)
    @v=Msg::Ver.new(self,1)
    @v.msg{"Init/Server:#{port}(#{type})"}
    super{
      Thread.pass
      UDPSocket.open{ |udp|
        udp.bind("0.0.0.0",port.to_i)
        loop {
          select([udp])
          line,addr=udp.recvfrom(4096)
          @v.msg{"Recv:#{line} is #{line.class}"}
          line='' if /^(strobe|stat)/ === line
          cmd=line.chomp.split(' ')
          begin
            msg=yield(cmd)
          rescue RuntimeError
            msg="ERROR"
            warn msg
          end
          @v.msg{"Send:#{msg}"}
          udp.send([msg,prompt].compact.join("\n"),0,addr[2],addr[1])
        }
      }
    }
  end
end
