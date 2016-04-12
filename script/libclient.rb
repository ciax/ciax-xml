#!/usr/bin/ruby
require 'libmsg'
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
      return self unless @port
      @stat.ext_http(@host)
      @pre_exe_procs << proc { @stat.upd }
      @sv_stat.add_flg(udperr: 'x')
      @sv_stat.pre_upd_procs << proc { exe([]) }
      @udp = UDPSocket.open
      verbose { "Initiate UDP client (#{@id}) [#{@host}:#{@port}]" }
      _set_client_proc
    end

    private

    def _set_client_proc
      @cobj.rem.def_proc do|ent|
        args = ent.id.split(':')
        # Address family not supported by protocol -> see above
        @udp.send(JSON.dump(args), 0, @host, @port.to_i)
        verbose { "UDP Send #{args}" }
        _udp_wait
      end
      self
    end

    def _udp_wait
      if IO.select([@udp], nil, nil, 1)
        _udp_recv
      else
        @sv_stat.up(:udperr).repl(:msg, 'TIMEOUT')
      end
    end

    def _udp_recv
      res = @udp.recv(1024)
      @sv_stat.dw(:udperr)
      verbose { "UDP Recv #{res}" }
      return if res.empty?
      @sv_stat.read(res)
      verbose { 'Prompt Loading from UDP' }
    end
  end
end
