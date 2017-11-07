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
        STDIN.tty? && msg('Ctrl-\ for exit')
        ___sv_loop(io)
      rescue
        log("#{$ERROR_INFO} #{$ERROR_POSITION}")
      end

      private

      def ___sv_loop(io)
        loop do
          str = ___input(io)
          log("#{self.class}:Recieve #{str.inspect}")
          res = _dispatch(str) || next
          res += @ofs
          log("#{self.class}:Send #{res.inspect}")
          io ? io.syswrite(res) : puts(res.inspect)
          sleep 0.1
        end
      end

      def ___input(io)
        if @length
          str = ' ' * @length
          io.sysread(@length, str)
        else
          str = gets
        end
        str ? str.chomp : ''
      end

      def _dispatch(str)
        cmd = (/=/ =~ str ? $` : str).to_sym
        res = @io.key?(cmd) ? ___handle_var(cmd, $') : _method_call(str)
        res.to_s
      rescue NameError, ArgumentError
        @prompt_ng
      end

      def ___handle_var(key, val)
        if val
          @io[key] = val
          @prompt_ok
        else
          @io[key]
        end
      end

      def _method_call(str, par = nil)
        me = method("_cmd_#{str}".to_sym)
        par ? me.call(par) : me.call || @prompt_ng
      end

      def _get_cmd_list
        methods.map(&:to_s).grep(/^_cmd_/).map do |s|
          s.sub(/^_cmd_/, '')
        end
      end
    end
  end
end
