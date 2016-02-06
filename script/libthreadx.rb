#!/usr/bin/ruby
require 'socket'
require 'libmsg'
require 'thread'

module CIAX
  # Extended Thread class
  class Threadx < Thread
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
    end

    def self.list
      Thread.list.map { |t| t[:name] }
    end

    # Reloadable by HUP signal
    def self.daemon(tag)
      # Set ARGS in opt file
      optfile = "#{ENV['HOME']}/.var/#{tag}.opt"
      pidfile = "#{ENV['HOME']}/.var/#{tag}.pid"
      IO.foreach(pidfile) do |line|
        pid = line.to_i
        next unless pid > 0
        begin
          Process.kill(:TERM,pid)
        rescue
        end
      end if test(?r, pidfile)
      Process.daemon(true,true)
      IO.write(pidfile, $$)
      begin
        load optfile if test(?r, optfile)
        exe = yield
        Msg.err2file(tag)
        exe.server
        sleep
      rescue SignalException
        retry if $ERROR_INFO.message == 'SIGHUP'
      end
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

  class ThreadUdp < Threadx
    def initialize(name, color = 4)
      super do
        begin
          udp = UDPSocket.open
          udp.bind('0.0.0.0', @port.to_i)
          loop {  yield(udp) }
        ensure
          udp.close
        end
      end
      sleep 0.3
    end
  end
end
