#!/usr/bin/ruby
# I/O Simulator
require 'libenumx'
require 'gserver'
module CIAX
  # Device Simulater
  module Simulator
    # Simulation Server
    class Server < GServer
      include Msg
      def initialize(port, *args)
        super
        Thread.abort_on_exception = true
        @io = {}
        @separator = "\n"
        @prompt_ok = '>'
        @prompt_ng = '?'
      end

      def serve(io = nil)
        selectio(io)
        while (str = gets.chomp)
          sleep 0.1
          print dispatch(str).to_s + $INPUT_RECORD_SEPARATOR
        end
      rescue
        warn $ERROR_INFO
      end

      def start
        bname = File.basename($0, '.rb')
        self.stdlog = Msg.vardir('log') + bname + '.log'
        Process.daemon(true,true)
        verbose { "Starting daemon #{bname}"}
        super()
        sleep
      end

      private

      # For Background
      def selectio(io)
        return unless io
        $stdin = $stdout = io
        $/ = @separator
      end

      def dispatch(str)
        cmd = (/=/ =~ str ? $` : str).to_sym
        return method_call(str) unless @io.key?(cmd)
        par = $'
        if par
          @io[cmd]=par
          @prompt_ok
        else
          @io[cmd]
        end
      rescue NameError, ArgumentError
        @prompt_ng
      end

      def method_call(str)
        cmd = 'cmd_' + str
        method(cmd).call || @prompt_ng
      end
    end
  end
end
