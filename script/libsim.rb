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
        @cfg = cfg || Conf.new
        ___init_instance
        self.stdlog = @cfg[:stdlog]
        self.audit = true
        self.debug = true
      end

      def serve(io = nil)
        # @length = nil => tty I/O
        unless io
          @length = nil
          msg('Ctrl-\ for exit')
        end
        ___sv_loop(io)
      rescue
        log("#{$ERROR_INFO} #{$ERROR_POSITION}")
        raise unless io
      end

      private

      def ___init_instance
        @io = {}
        @prompt_ok = '>'
        @prompt_ng = '?'
        # @length is set when STDIN is stream
        @length = 1024
        @ifs = @ofs = $OUTPUT_RECORD_SEPARATOR
        @dev_dic = @cfg[:dev_dic]
        # Mask loading info
        @mask_load = false
      end

      def ___sv_loop(io)
        loop do
          str = ___input(io)
          log("#{self.class}:Recieve #{str.inspect}")
          res = _dispatch(str) || next
          res << @ofs if @ofs
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

    # Run object for Daemon
    class SimList < Array
      attr_reader :id
      def initialize
        @id = 'dmcs'
      end

      def gen
        map! { |mod| mod.new(Conf.new) }
      end

      def run
        each(&:start)
      end
    end

    @sim_list = SimList.new
  end
end
