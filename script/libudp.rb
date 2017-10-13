#!/usr/bin/ruby
require 'socket'
require 'libmsg'

module CIAX
  # UDP Server Thread with Loop
  class UdpServer
    def initialize(port)
      @udp = UDPSocket.open
      @udp.bind('0.0.0.0', port.to_i)
    end

    def listen
      loop do
        IO.select([@udp])
        line, addr = @udp.recvfrom(4096)
        rhost = Addrinfo.ip(addr[2]).getnameinfo.first
        send_str = yield(line, rhost)
        @udp.send(send_str, 0, addr[2], addr[1])
      end
    ensure
      @udp.close
    end
  end
end
