#!/usr/bin/env ruby
require 'libudp'

# Provide Client
module CIAX
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
