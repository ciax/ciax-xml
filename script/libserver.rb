#!/usr/bin/env ruby
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
        return self unless @port
        @mode += ':SV'
        @cobj.rem.sys.add_empty
        @server_input_proc ||= ___init_input
        @sv_stat.ext_local.ext_save.ext_local_log
        @server_output_proc ||= proc { JSON.dump(@sv_stat) }
        ___startup
        self
      end

      private

      # If first arg is number, it is stored in Prompt as a sequencial number
      def ___init_input
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
      def ___startup
        Threadx::Fork.new('Server', @layer, @id, port: "udp:#{@port}") do
          ___srv_udp
          sleep 0.3
        end
        self
      end

      def ___srv_udp
        Udp::Server.new(@layer, @id, @port).listen do |line, rhost|
          ___srv_exec(line, rhost)
          @server_output_proc.call
        end
      end

      def ___srv_exec(line, rhost)
        verbose { "Exec Server\nValid Commands #{@cobj.valid_keys}" }
        exe(@server_input_proc.call(line), "udp:#{rhost}")
      rescue
        @sv_stat.seterr
        errmsg
      end
    end
  end
end
