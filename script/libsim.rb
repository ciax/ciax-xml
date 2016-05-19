#!/usr/bin/ruby
# I/O Simulator
require 'libsimconf'
require 'gserver'
module CIAX
  # Device Simulator
  module Simulator
    # Simulation Server
    class Server < GServer
      include Msg
      def initialize(port, cfg = nil)
        super(port)
        @io = {}
        @cfg = cfg || Conf.new
        @prompt_ok = '>'
        @prompt_ng = '?'
        stdlog = @cfg[:stdlog]
        audit = true
      end

      def serve(io = nil)
        selectio(io)
        while (str = input(io))
          verbose{ "Recieve #{str.inspect}" }
          res = dispatch(str)
          verbose{ "Send #{res.inspect}" }
          print io ? res + @separator.to_s : res.inspect if res
          sleep 0.1
        end
      rescue
        warn $ERROR_INFO
      end

      private

      # For Background
      def selectio(io)
        if io
          $stdin = $stdout = io
          $/ = @separator
        else
          @length = nil
        end
      end

      def input(io)
        if @length
          io.readpartial(@length)
        else
          str = gets
          str ? str.chomp : ''
        end
      end

      def dispatch(str)
        cmd = (/=/ =~ str ? $` : str).to_sym
        res = @io.key?(cmd) ? handle_var(cmd, $') : method_call(str)
        res.to_s + $INPUT_RECORD_SEPARATOR
      rescue NameError, ArgumentError
        @prompt_ng
      end

      def handle_var(key, val)
        if val
          @io[key] = val
          @prompt_ok
        else
          @io[key]
        end
      end

      def method_call(str)
        cmd = 'cmd_' + str
        method(cmd).call || @prompt_ng
      end
    end
  end
end
