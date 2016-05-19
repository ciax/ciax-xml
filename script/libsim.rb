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
        self.stdlog = @cfg[:stdlog]
        self.audit = true
        @ifs = @ofs = $OUTPUT_RECORD_SEPARATOR
      end

      def serve(io = nil)
        selectio(io)
        loop do
          str = input(io)
          verbose { "Recieve #{str.inspect}" }
          res = dispatch(str) || next
          res += @ofs
          verbose { "Send #{res.inspect}" }
          io ? io.print(res) : puts(res.inspect)
        end
      rescue
        warn $ERROR_INFO
      end

      private

      # For Background
      def selectio(io)
        return if io
        @length = nil
      end

      def input(io)
        if @length
          io.readpartial(@length)
        elsif io
          str = io.gets(@ifs)
          str ? str.chomp : ''
        else
          str = gets.chomp
        end
      end

      def dispatch(str)
        cmd = (/=/ =~ str ? $` : str).to_sym
        res = @io.key?(cmd) ? handle_var(cmd, $') : method_call(str)
        res.to_s
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
