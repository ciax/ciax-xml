#!/usr/bin/ruby
require 'libudp'

# Provide Server
module CIAX
  # Device Processing
  class Exe
    # Server extension module
    module Server
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      # JSON expression of server stat will be sent.
      def ext_local_server
        return self if @mode == 'CL' || !@port
        @mode += ':SV'
        @server_input_proc = _init_input_
        @sv_stat.ext_local_file.auto_save.ext_local_log
        @server_output_proc = proc { JSON.dump(@sv_stat) }
        _startup_
        self
      end

      private

      # If first arg is number, it is stored in Prompt as a sequencial number
      def _init_input_
        proc do |line|
          args = type?(j2h(line), Array)
          if args[0].to_i > 0
            @sv_stat.put(:sn, args.shift)
          else
            @sv_stat.del(:sn)
          end
          args
        end
      end

      # Separated form ext_* for detach process of this part
      def _startup_
        Threadx::Fork.new('Server', @layer, @id, "udp:#{@port}") do
          _srv_udp_
          sleep 0.3
        end
        self
      end

      def _srv_udp_
        Udp::Server.new(@layer, @id, @port).listen do |line, rhost|
          _srv_exec_(line, rhost)
          @server_output_proc.call
        end
      end

      def _srv_exec_(line, rhost)
        verbose { "Exec Server\nValid Commands #{@cobj.valid_keys}" }
        exe(@server_input_proc.call(line), "udp:#{rhost}")
      rescue
        @sv_stat.seterr
        errmsg
      end
    end
  end
end
