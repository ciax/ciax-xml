#!/usr/bin/ruby
require 'socket'
require 'libmsg'
require 'thread'

module CIAX
  # Extended Thread class
  class Threadx < Thread
    Threads = ThreadGroup.new
    include Msg
    def initialize(tname, id)
      th = super { _do_proc(id) { yield } }
      th[:name] = tname
      Threads.add(th)
    end

    def self.list
      Thread.list.map { |t| t[:name] }
    end

    def self.killall
      Threads.list.each(&:kill)
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
  class ThreadLoop < Threadx
    def initialize(name, id)
      super do
        loop do
          yield
          verbose { "Next for #{Thread.current[:name]}" }
        end
      end
    end
  end

  # UDP Server Thread
  class ThreadUdp < Threadx
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
