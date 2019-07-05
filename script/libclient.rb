#!/usr/bin/env ruby
require 'libudp'

# Provide Client
module CIAX
  class Exe
    # Remote module
    module Remote
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      def ext_remote
        @mode = 'CL'
        self
      end

      # Remote setting for sv_stat (will be applied for App/Frm)
      def _remote_sv_stat
        @sv_stat.ext_remote(@host, @port)
        @cobj.rem.add_empty
        @cobj.rem.def_proc { |ent| @sv_stat.send(ent.id) }
      end

      # Should be done after _remote_sv_stat()
      # @stat will be generated according to sv_stat response at macro
      def _remote_stat
        @stat.ext_remote(@host)
        @sv_stat.upd_procs.append(self, :exe) { @stat.upd }
      end
    end
  end
  # Device Processing
  class Prompt
    # Client module
    module Client
      def self.extended(obj)
        Msg.type?(obj, Prompt)
      end

      # If you get a system error 'Address family not ..',
      # remove ipv6 entry from /etc/hosts
      def ext_remote(host, port)
        init_flg(udperr: 'x')
        @udp = Udp::Client.new(host, port)
        @upd_procs.append(self, :client) { send }
        self
      end

      def send(str = '')
        @udp.send(JSON.dump(str.split(':')))
        ___udp_recv || up(:udperr).repl(:msg, 'TIMEOUT')
        self
      end

      private

      def ___udp_recv
        return unless (res = @udp.recv)
        dw(:udperr)
        return if res.empty?
        jmerge(res)
        verbose { cfmt('Prompt Loading from UDP (%s) %p', @host, self) }
        cmt
      end
    end
  end
end
