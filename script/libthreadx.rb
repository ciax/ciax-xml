#!/usr/bin/ruby
require 'socket'
require 'libmsg'
require 'thread'

module CIAX
  # Extended Thread class
  class Threadx < Thread
    Threads = ThreadGroup.new
    NS_COLOR = 4
    include Msg
    def initialize(name, color = 4)
      Thread.abort_on_exception = true
      th = super do
        Thread.pass
        yield
      end
      th[:name] = name
      th[:color] = color
      Threads.add(th)
    end

    def self.list
      Thread.list.map { |t| t[:name] }
    end

    def self.killall
      Threads.list.each(&:kill)
    end
  end

  # Thread with Loop
  class ThreadLoop < Threadx
    def initialize(name, color = 4)
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
    def initialize(name, port)
      super(name, 9) do
        begin
          udp = UDPSocket.open
          udp.bind('0.0.0.0', port.to_i)
          loop { yield(udp) }
        ensure
          udp.close
        end
      end
      sleep 0.3
    end
  end
end
