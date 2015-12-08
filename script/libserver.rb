#!/usr/bin/ruby
require 'socket'

# Provide Server
module CIAX
  # Server extension module
  module Server
    def self.extended(obj)
      Msg.type?(obj, Exe)
    end

    # JSON expression of server stat will be sent.
    def ext_server
      @sub.ext_server if @sub
      return self unless @port
      verbose { "Initialize UDP server (#{@id}) [#{@port}]" }
      @server_input_proc = proc { |line| j2h(line) }
      @sv_stat.ext_file.auto_save.ext_log
      @server_output_proc = proc { @sv_stat.to_j }
      self
    end

    def server
      @sub.server if @sub
      return self unless @port
      udp = UDPSocket.open
      udp.bind('0.0.0.0', @port.to_i)
      ThreadLoop.new("Server(#{@layer}:#{@id})", 9) do
        IO.select([udp])
        line, addr = udp.recvfrom(4096)
        line.chomp!
        rhost = Addrinfo.ip(addr[2]).getnameinfo.first
        verbose { "Exec Server\nValid Commands #{@cobj.valid_keys}" }
        verbose { "UDP Recv:#{line} is #{line.class}" }
        begin
          exe(@server_input_proc.call(line), "udp:#{rhost}")
        rescue InvalidCMD
          @sv_stat.msg('INVALID')
        rescue
          @sv_stat.msg("ERROR:#{$ERROR_INFO}")
          errmsg
        end
        send_str = @server_output_proc.call
        verbose { "UDP Send:#{send_str}" }
        udp.send(send_str, 0, addr[2], addr[1])
      end
      self
    end
  end
end
