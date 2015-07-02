#!/usr/bin/ruby
require "socket"

# Provide Server
module CIAX
  module Server
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # JSON expression of server stat will be sent.
    def ext_server(port)
      verbose("Initialize [#@id:#{port}]")
      @server_input_proc=proc{|line|
        begin
          JSON.load(line)
        rescue JSON::ParserError
          raise "NOT JSON"
        end
      }
      @server_output_proc=proc{ merge(@site_stat).to_j }
      @cobj.rem.hid.add_nil
      udp=UDPSocket.open
      udp.bind("0.0.0.0",port.to_i)
      ThreadLoop.new("Server(#@layer:#@id)",9){
        IO.select([udp])
        line,addr=udp.recvfrom(4096)
        line.chomp!
        rhost=Addrinfo.ip(addr[2]).getnameinfo.first
        verbose("Exec Server","Valid Commands #{@cobj.valid_keys}")
        verbose("Recv:#{line} is #{line.class}")
        begin
          exe(@server_input_proc.call(line),"udp:#{rhost}")
        rescue InvalidCMD
          self['msg']="INVALID"
        rescue
          self['msg']=$!.to_s
          errmsg
        end
        send_str=@server_output_proc.call
        verbose("Send:#{send_str}")
        udp.send(send_str,0,addr[2],addr[1])
      }
      self
    end
  end
end
