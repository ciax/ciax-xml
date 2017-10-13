#!/usr/bin/ruby
# Provide Server
module CIAX
  # Server extension module
  module Server
    def self.extended(obj)
      Msg.type?(obj, Exe)
    end

    # JSON expression of server stat will be sent.
    def ext_local_server
      return self unless @port
      verbose { "Initiate UDP server (#{@id}) port:[#{@port}]" }
      @server_input_proc = _init_input
      @sv_stat.ext_local_file.auto_save.ext_local_log
      @server_output_proc = proc { JSON.dump(@sv_stat) }
      _startup
      self
    end

    private

    # If first arg is number, it is stored in Prompt as a sequencial number
    def _init_input
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
    def _startup
      Threadx::UdpLoop.new('Server', @layer, @id, @port) do |line, rhost|
        verbose { "UDP Recv:#{line} is #{line.class}" }
        _srv_exec(line, rhost)
        send_str = @server_output_proc.call
        verbose { "UDP Send:#{send_str}" }
        send_str
      end
      self
    end

    def _srv_exec(line, rhost)
      verbose { "Exec Server\nValid Commands #{@cobj.valid_keys}" }
      exe(@server_input_proc.call(line), "udp:#{rhost}")
    rescue
      @sv_stat.seterr
      errmsg
    end
  end
end
