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
    def ext_client(host,port)
      host||='localhost'
      @site_stat.add_db('udperr' => 'x')
      @udp=UDPSocket.open()
      verbose("UDP:Client","Initialize [#@id/#{host}:#{port}]")
      @addr=Socket.pack_sockaddr_in(port.to_i,host)
      @cobj.rem.cfg.proc{|ent|
        args=ent.id.split(':')
        # Address family not supported by protocol -> see above
        @udp.send(JSON.dump(args),0,@addr)
        verbose("UDP:Client","Send #{args}")
        if IO.select([@udp],nil,nil,1)
          res=@udp.recv(1024)
          @site_stat['udperr']=false
          verbose("UDP:Client","Recv #{res}")
          update(@site_stat.pick(JSON.load(res))) unless res.empty?
        else
          @site_stat['udperr']=true
          self['msg']='TIMEOUT'
        end
        self['msg']
      }
      self
    end
  end
end
