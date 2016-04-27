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
      verbose do
        "Initiate UDP server (#{@id}) port:[#{@port}] git:[" +
          `cd #{__dir__};git reflog`.split(' ').first + ']'
      end
      @server_input_proc = proc { |line| j2h(line) }
      @sv_stat.ext_local_file.auto_save.ext_local_log
      @server_output_proc = proc { @sv_stat.to_j }
      server_thread
    end

    private

    def server_thread
      ThreadUdp.new("Server(#{@layer}:#{@id})", @port) do |udp|
        line, addr = udp.recvfrom(4096)
        line.chomp!
        verbose { "UDP Recv:#{line} is #{line.class}" }
        _srv_exec(line, addr)
        send_str = @server_output_proc.call
        verbose { "UDP Send:#{send_str}" }
        udp.send(send_str, 0, addr[2], addr[1])
      end
      self
    end

    def _srv_exec(line, addr)
      verbose { "Exec Server\nValid Commands #{@cobj.valid_keys}" }
      rhost = Addrinfo.ip(addr[2]).getnameinfo.first
      exe(@server_input_proc.call(line), "udp:#{rhost}")
    rescue InvalidCMD
      @sv_stat.repl(:msg, 'INVALID')
    rescue
      @sv_stat.repl(:msg, "ERROR:#{$ERROR_INFO}")
      errmsg
    end
  end
end
