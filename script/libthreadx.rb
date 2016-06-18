#!/usr/bin/ruby
require 'socket'
require 'libmsg'
require 'thread'

module CIAX
  # Extended Thread class
  module Threadx
    Threads = ThreadGroup.new

    module_function

    def list
      Thread.list.map do |t|
        %i(layer name id).map { |id| t[id] }.push(t.status).join(':')
      end.sort
    end

    def killall
      Threads.list.each(&:kill)
    end

    # Simple Extention
    class Fork < Thread
      include Msg
      def initialize(tname, layer, id)
        @layer = layer
        th = super { _do_proc(id) { yield } }
        th[:layer] = layer
        th[:name] = tname
        th[:id] = id
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
      def initialize(tname, layer, id)
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
      def initialize(tname, layer, id)
        @in = Queue.new
        @out = Queue.new
        super { yield @in, @out }
      end

      def push(str)
        warning("Thread [#{self[:name]}] is not running") unless alive?
        @in.push(str)
        self
      end

      def shift
        @out.shift
      end

      def clear
        @in.clear
        @out.clear
        self
      end
    end

    # Queue Thread with Loop
    class QueLoop < Que
      def initialize(tname, layer, id)
        super { |i, o| loop { yield i, o } }
      end
    end

    # UDP Server Thread
    class Udp < Fork
      def initialize(name, layer, id, port)
        super(name, layer, id) do
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
