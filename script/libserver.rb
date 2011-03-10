#!/usr/bin/ruby
require "socket"
require "libverbose"

class Server
  def initialize(port)
    @v=Verbose.new("UDPS")
    UDPSocket.open{ |udp|
      udp.bind("0.0.0.0",port)
      loop {
        begin
          select([udp])
          line,addr=udp.recvfrom(1024)
          @v.msg{"#{line} is #{line.class}"}
          line.chomp!
          msg=yield line
        rescue RuntimeError
          msg=$!.to_s
        end
        udp.send(msg,0,addr[2],addr[1])
      }
    }
  end
end
