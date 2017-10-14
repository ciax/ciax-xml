#!/usr/bin/ruby
# I/O Simulator
# Need GServer: sudo gem install gserver
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
        self.debug = true
        @length = 1024
        @ifs = @ofs = $OUTPUT_RECORD_SEPARATOR
      end

      def serve(io = nil)
        # @length = nil => tty I/O
        @length = nil unless io
        sv_loop(io)
      rescue
        log($ERROR_INFO + $ERROR_POSITION)
      end

      private

      def sv_loop(io)
        loop do
          str = input(io)
          log("#{self.class}:Recieve #{str.inspect}")
          res = dispatch(str) || next
          res += @ofs
          log("#{self.class}:Send #{res.inspect}")
          io ? io.syswrite(res) : puts(res.inspect)
          sleep 0.1
        end
      end

      def input(io)
        if @length
          str = ' ' * @length
          io.sysread(@length, str)
        else
          str = gets
        end
        str ? str.chomp : ''
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
