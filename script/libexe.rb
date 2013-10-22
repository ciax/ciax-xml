#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libextcmd"

# Provide Server,Client
# Integrate Command,Status
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  class Exe < Hashx # Having server status {id,msg,...}
    attr_reader :layer,:id,:upd_procs,:post_procs,:cobj,:output
    # block gives command line convert
    def initialize(layer,id,cobj=Command.new)
      @id=id
      @layer=layer
      @cobj=type?(cobj,Command)
      @cobj.interrupt.set_proc{
        interrupt
        "INTERRUPT"
      }
      @pre_procs=[] # Proc for Command Check (by User exec)
      @post_procs=[] # Proc for Command Issue (by User exec)
      @upd_procs=[] # Proc for Server Status Update (by User query)
      @ver_color=6
      self['msg']=''
      Thread.abort_on_exception=true
    end

    # Sync only (Wait for other thread)
    def exe(args)
      type?(args,Array)
      @pre_procs.each{|p| p.call(args)}
      verbose("Sh/Exe","Command #{args} recieved")
      self['msg']=@cobj.setcmd(args).exe
      @post_procs.each{|p| p.call(args)}
      self
    rescue
      self['msg']=$!.to_s
      raise $!
    ensure
      @upd_procs.each{|p| p.call}
    end

    def interrupt ;end

    def ext_client(host,port)
      extend(Client).ext_client(host,port)
    end

    def ext_server(port)
      extend(Server).ext_server(port)
    end

    def ext_shell(output={},pdb={},pstat=nil)
      extend(Shell).ext_shell(output,pdb,pstat)
    end

    # Overridable methods(do not set this kind of methods in modules)
    private
    def shell_input(line)
      line.split(' ')
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
      verbose("UDP:Server/#{self.class}","Init/Server(#@id):#{port}",2)
      Threadx.new("Server Thread(#@layer:#@id)",9){
        UDPSocket.open{ |udp|
          udp.bind("0.0.0.0",port.to_i)
          loop {
            IO.select([udp])
            line,addr=udp.recvfrom(4096)
            line.chomp!
            verbose("UDP:Server/#{self.class}","Recv:#{line} is #{line.class}",2)
            begin
              exe(server_input(line))
            rescue InvalidCMD
              self['msg']="INVALID"
            rescue RuntimeError
              warn($!.to_s)
              self['msg']=$!.to_s
            end
            verbose("UDP:Server/#{self.class}","Send:#{self['msg']}",2)
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

    def ext_client(host,port)
      host||='localhost'
      @udp=UDPSocket.open()
      @addr=Socket.pack_sockaddr_in(port.to_i,host)
      verbose("UDP:Client/#{self.class}","Init/Client(#@id):#{host}:#{port}",6)
      @cobj.svdom.set_proc{|ent|
        args=ent.id.split(':')
        @udp.send(JSON.dump(args),0,@addr)
        verbose("UDP:Client/#{self.class}","Send [#{args}]",6)
        res=@udp.recv(1024)
        verbose("UDP:Client/#{self.class}","Recv #{res}",6)
        update(JSON.load(res)) unless res.empty?
        self['msg']
      }
      self
    end
  end

  class ExeList < Hashx
    attr_reader :init_procs
    # shdom: Domain for Shared Command Groups
    def initialize(&new_proc)
      $opt||=GetOpts.new
      @init_procs=[] # initialize exe (mostly add new menu) at new key generated
    end

    def [](key)
      if key?(key)
        super
      else
        exe=self[key]=new_val(key)
        @init_procs.each{|p| p.call(exe)}
        exe
      end
    end

    def server(ary)
      ary.each{|i|
        sleep 0.3
        self[i]
      }.empty? && self[nil]
      sleep
    rescue InvalidID
      $opt.usage('(opt) [id] ....')
    end

    private
    # For generate Exe (allows nil)
    def new_val(key)
    end
  end
end
