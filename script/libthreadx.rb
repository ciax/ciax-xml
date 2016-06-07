#!/usr/bin/ruby
require 'socket'
require 'libmsg'
require 'thread'

module CIAX
  # Extended Thread class
  module Threadx
    extend self
    Threads = ThreadGroup.new

    def list
      Thread.list.map { |t| t[:name] }
    end

    def killall
      Threads.list.each(&:kill)
    end

    class Fork < Thread
      include Msg
      def initialize(tname, id)
        th = super { _do_proc(id) { yield } }
        th[:name] = tname
        Threads.add(th)
      end

      private

      def _do_proc(id)
        Thread.pass
        verbose { "Initiate Thread (#{id})" }
        yield
      rescue
        errmsg
      end
    end
    # Thread with Loop
    class Loop < Fork
      def initialize(name, id)
        super do
          loop do
            yield
            verbose { "Next for #{Thread.current[:name]}" }
          end
        end
      end
    end

    # Queue Thread
    class Que < Fork
      attr_reader :queue
      def initialize(name, id)
        @queue = Queue.new
        super do
          loop do
            yield @queue
          end
        end
      end
    end

    # UDP Server Thread
    class Udp < Fork
      def initialize(name, id, port)
        super(name, id) do
          udp = UDPSocket.open
          udp.bind('0.0.0.0', port.to_i)
          _udp_loop(udp) { |line, rhost| yield(line, rhost) }
        end
        sleep 0.3
      end

      private

      def _udp_loop(udp, &th_proc)
        loop do
          IO.select([udp])
          line, addr = udp.recvfrom(4096)
          rhost = Addrinfo.ip(addr[2]).getnameinfo.first
          send_str = th_proc.call(line, rhost)
          udp.send(send_str, 0, addr[2], addr[1])
        end
      ensure
        udp.close
      end
    end
  end
end
