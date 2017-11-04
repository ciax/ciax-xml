#!/usr/bin/ruby
require 'libudp'

# Provide Client
module CIAX
  # Device Processing
  class Exe
    # Client module
    module Client
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      # If you get 'Address family not ..' error,
      # remove ipv6 entry from /etc/hosts
      def ext_client
        @mode = 'CL'
        @stat.ext_http(@host)
        @pre_exe_procs << proc { @stat.upd }
        _init_upd if @port
        self
      end

      private

      def _init_upd
        @sv_stat.init_flg(udperr: 'x')
        @sv_stat.upd_procs << proc { exe([]) }
        @udp = Udp::Client.new(@layer, @id, @host, @port)
        ___set_client_proc
      end

      def ___set_client_proc
        @cobj.rem.def_proc do |ent|
          @udp.send(ent.id.split(':'))
          ___udp_recv
        end
        self
      end

      def ___udp_recv
        if (res = @udp.recv)
          @sv_stat.dw(:udperr)
          return if res.empty?
          @sv_stat.jmerge(res)
          verbose { 'Prompt Loading from UDP' }
        else
          @sv_stat.up(:udperr).repl(:msg, 'TIMEOUT')
        end
      end
    end
  end
end
