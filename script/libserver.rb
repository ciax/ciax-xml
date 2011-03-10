#!/usr/bin/ruby
require "socket"

class Server
  def initialize(port)
    UDPSocket.open{ |udp|
      udp.bind("0.0.0.0",port)
      loop {
        begin
          select([udp])
          line,addr=udp.recvfrom(1024)
          msg=yield line.chomp!
        rescue RuntimeError
          msg=$!.to_s
        end
        udp.send(msg,0,addr[2],addr[1])
      }
    }
  end
end
