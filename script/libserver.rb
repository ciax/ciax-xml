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
      @server_input_proc = proc { |line| j2h(line) }
      @sv_stat.ext_local_file.auto_save.ext_local_log
      @server_output_proc = proc { JSON.dump(@sv_stat) }
      _startup
      self
    end

    private

    # Separated form ext_* for detach process of this part
    def _startup
      ThreadUdp.new("Server(#{@layer})", @id, @port) do |line, rhost|
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
    rescue InvalidCMD
      @sv_stat.repl(:msg, 'INVALID')
    rescue
      @sv_stat.repl(:msg, "ERROR:#{$ERROR_INFO}")
      errmsg
    end
  end
end
