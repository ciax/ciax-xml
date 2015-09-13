#!/usr/bin/ruby
require "socket"

# Provide Client
module CIAX
  module Client
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # If you get 'Address family not ..' error,
    # remove ipv6 entry from /etc/hosts
    def ext_client
      host=@cfg['host']
      port=@cfg['port']
      @site_stat.add_db('udperr' => 'x')
      @udp=UDPSocket.open()
      verbose("Initialize UDP client (#@id) [#{host}:#{port}]")
      @cobj.rem.def_proc{|ent|
        args=ent.id.split(':')
        # Address family not supported by protocol -> see above
        @udp.send(JSON.dump(args),0,host,port.to_i)
        verbose("UDP Send #{args}")
        if IO.select([@udp],nil,nil,1)
          res=@udp.recv(1024)
          @site_stat.reset('udperr')
          verbose("UDP Recv #{res}")
          update(@site_stat.update(JSON.load(res))) unless res.empty?
          @site_stat.msg
        else
          @site_stat.set('udperr')
          'TIMEOUT'
        end
      }
      self
    end
  end
end
