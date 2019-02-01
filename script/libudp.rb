#!/usr/bin/env ruby
require 'socket'
require 'libmsg'

module CIAX
  module Udp
    # UDP Client
    class Client
      include Msg
      def initialize(layer, id, host, port)
        @layer = layer
        @id = id
        @host = host
        @port = port
        @udp = UDPSocket.open
        verbose { "Initiate UDP client (#{@id}) [#{@host}:#{@port}]" }
      end

      def send(str)
        # Address family not supported by protocol -> see above
        @udp.send(str, 0, @host, @port.to_i)
        verbose { "UDP Send #{args}" }
      end

      def recv
        return unless IO.select([@udp], nil, nil, 1)
        res = @udp.recv(1024)
        verbose { "UDP Recv #{res}" }
        res
      end
    end
    # UDP Server Thread with Loop
    class Server
      include Msg
      def initialize(layer, id, port, msg = '')
        @layer = layer
        @id = id
        verbose { "Initiate UDP server #{msg}(#{@id}) port:[#{port}]" }
        @udp = UDPSocket.open
        @udp.bind('0.0.0.0', port.to_i)
      end

      def listen
        loop do
          IO.select([@udp])
          ___send(yield(___recv))
        end
      ensure
        @udp.close
      end

      private

      def ___recv
        line, @addr = @udp.recvfrom(4096)
        verbose { "UDP Recv:#{line} is #{line.class}" }
        [line, Addrinfo.ip(@addr[2]).getnameinfo.first]
      end

      def ___send(send_str)
        @udp.send(send_str, 0, @addr[2], @addr[1])
        verbose { "UDP Send:#{send_str}" }
      end
    end
  end
end
