#!/usr/bin/ruby
require "socket"
require "libverbose"

class Server
  def initialize(port)
    @v=Verbose.new("UDPS")
    @v.msg{"Prompt:#{prom.inspect}"}
    @v.add("interrupt" => "Interrupt")
    UDPSocket.open{ |udp|
      udp.bind("0.0.0.0",port)
      loop {
        select([udp])
        line,addr=udp.recvfrom(1024)
        @v.msg{"Recv:#{line} is #{line.class}"}
        begin
          msg=yield(/interrupt/ === line ? nil : line.chomp)
        rescue SelectID
          msg=@v.to_s
        rescue RuntimeError
          msg=$!.to_s
          warn msg
        end
        @v.msg{"Send:#{msg},#{prom}"}
        udp.send(msg.to_s+"\n",0,addr[2],addr[1])
      }
    }
  end
end
