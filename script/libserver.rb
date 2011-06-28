#!/usr/bin/ruby
require "socket"
require "libverbose"

class Server
  def initialize(port)
    @v=Verbose.new("UDPS")
    UDPSocket.open{ |udp|
      udp.bind("0.0.0.0",port)
      loop {
        select([udp])
        line,addr=udp.recvfrom(1024)
        @v.msg{"#{line} is #{line.class}"}
        begin
          msg=yield line.chomp
        rescue RuntimeError
          msg=$!
          warn msg
        end
        udp.send(msg.to_s,0,addr[2],addr[1])
      }
    }
  end
end
