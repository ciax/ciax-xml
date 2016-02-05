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
    def self.reload(tag)
      # Set ARGS in opt file
      file = "#{ENV['HOME']}/.var/#{tag}.opt"
      load file if File.exist?(file) 
      yield(ARGS)
    rescue SignalException
      Thread.list {|t| t[:udp].close if t[:udp]}
      retry if $ERROR_INFO.message == 'SIGHUP'
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
        udp = UDPSocket.open
        udp.bind('0.0.0.0', @port.to_i)
        Thread.current[:udp] = udp
        loop {  yield(udp) }
      end
    end
  end
end
