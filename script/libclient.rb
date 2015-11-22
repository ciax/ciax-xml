#!/usr/bin/ruby
require 'socket'

# Provide Client
module CIAX
  # Client module
  module Client
    def self.extended(obj)
      Msg.type?(obj, Exe)
    end

    # If you get 'Address family not ..' error,
    # remove ipv6 entry from /etc/hosts
    def ext_client
      @sub.ext_client if @sub
      return self unless @port
      @sv_stat.add_db('udperr' => 'x')
      @udp = UDPSocket.open
      verbose { "Initialize UDP client (#{@id}) [#{@host}:#{@port}]" }
      @cobj.rem.def_proc do|ent|
        args = ent.id.split(':')
        # Address family not supported by protocol -> see above
        @udp.send(JSON.dump(args), 0, @host, @port.to_i)
        verbose { "UDP Send #{args}" }
        if IO.select([@udp], nil, nil, 1)
          res = @udp.recv(1024)
          @sv_stat.reset('udperr')
          verbose { "UDP Recv #{res}" }
          @sv_stat.read(res) unless res.empty?
          @sv_stat.msg
        else
          @sv_stat.set('udperr')
          'TIMEOUT'
        end
      end
      self
    end
  end
end
