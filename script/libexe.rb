#!/usr/bin/ruby
require "socket"
require "readline"
require "libextcmd"

# Provide Server,Client
# Integrate Command,Status
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  class Exe < Hashx # Having server status {id,msg,...}
    attr_reader :layer,:id,:mode,:pre_exe_procs,:post_exe_procs,:cobj,:output
    # block gives command line convert
    def initialize(layer,id,cobj=Command.new)
      @id=id
      @layer=layer
      @cobj=type?(cobj,Command)
      @pre_exe_procs=[] # Proc for Server Command (by User query)
      @post_exe_procs=[] # Proc for Server Status Update (by User query)
      @cls_color=7
      @pfx_color=9
      self['msg']=''
      Thread.abort_on_exception=true
    end

    # Sync only (Wait for other thread), never inherit
    def exe(args,src,pri=1)
      type?(args,Array)
      verbose("Sh/Exe","Command #{args} recieved")
      @pre_exe_procs.each{|p| p.call(args)}
      self['msg']=@cobj.set_cmd(args).exe_cmd(src,pri)
      self
    rescue LongJump
      raise $!
    rescue InvalidID
      self['msg']=$!.to_s
      raise $!
    rescue
      self['msg']=$!.to_s
      Msg.relay(args.first)
    ensure
      @post_exe_procs.each{|p| p.call(self)}
    end

    def ext_client(host,port)
      extend(Client).ext_client(host,port)
    end

    def ext_server(port)
      extend(Server).ext_server(port)
    end

    def ext_shell(output={},&prompt_proc)
      extend(Shell).ext_shell(output,&prompt_proc)
    end

    # Overridable methods(do not set this kind of methods in modules)
    private
    def shell_input(line)
      args=line.split(' ')
      if (cmd=args.first) && cmd.include?('=')
        args=['set']+cmd.split('=')
      end
      args
    end

    def shell_output
      self['msg'].empty? ? @output : self['msg']
    end

    def server_input(line)
      JSON.load(line)
    rescue JSON::ParserError
      raise "NOT JSON"
    end

    def server_output
      to_j
    end
  end

  module Server
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # JSON expression of server stat will be sent.
    def ext_server(port)
      verbose("UDP:Server","Init(#@id):#{port}")
      Threadx.new("Server(#@id)",9){
        UDPSocket.open{ |udp|
          udp.bind("0.0.0.0",port.to_i)
          loop {
            IO.select([udp])
            line,addr=udp.recvfrom(4096)
            line.chomp!
            rhost=Addrinfo.ip(addr[2]).getnameinfo.first
            verbose("UDP:Server/#{self.class}","Recv:#{line} is #{line.class}")
            begin
              exe(server_input(line),"udp:#{rhost}")
            rescue InvalidCMD
              self['msg']="INVALID"
            rescue RuntimeError
              self['msg']=$!.to_s
              errmsg
            end
            verbose("UDP:Server/#{self.class}","Send:#{self['msg']}")
            udp.send(server_output,0,addr[2],addr[1])
          }
        }
      }
      self
    end
  end

  module Client
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # If you get 'Address family not ..' error,
    # remove ipv6 entry from /etc/hosts
    def ext_client(host,port)
      @mode='CL'
      host||='localhost'
      @udp=UDPSocket.open()
      @addr=Socket.pack_sockaddr_in(port.to_i,host)
      verbose("UDP:Client","Init/Client(#@id):#{host}:#{port}")
      @cobj.svdom.set_proc{|ent|
        args=ent.id.split(':')
        @udp.send(JSON.dump(args),0,@addr) # Address family not supported by protocol -> see above
        verbose("UDP:Client","Send [#{args}]")
        res=@udp.recv(1024)
        verbose("UDP:Client","Recv #{res}")
        update(JSON.load(res)) unless res.empty?
        self['msg']
      }
      self
    end
  end
end
