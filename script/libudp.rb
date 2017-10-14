#!/usr/bin/ruby
require 'socket'
require 'libmsg'

module CIAX
  # UDP Server Thread with Loop
  class UdpServer
    include Msg
    def initialize(port)
      @udp = UDPSocket.open
      @udp.bind('0.0.0.0', port.to_i)
    end

    def listen
      loop do
        IO.select([@udp])
        _send(yield(_recv))
      end
    ensure
      @udp.close
    end

    private

    def _recv
      line, @addr = @udp.recvfrom(4096)
      verbose { "UDP Recv:#{line} is #{line.class}" }
      [line, Addrinfo.ip(@addr[2]).getnameinfo.first]
    end

    def _send(send_str)
      @udp.send(send_str, 0, @addr[2], @addr[1])
      verbose { "UDP Send:#{send_str}" }
    end
  end
end
