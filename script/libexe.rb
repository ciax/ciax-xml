#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libextcmd"
require "libupdate"

# Provide Server,Client
# Integrate Command,Status
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  class Exe < Hashx # Having server status {id,msg,...}
    attr_reader :upd_proc,:post_proc,:save_proc,:cobj,:output
    # block gives command line convert
    def initialize(layer,id,cobj=Command.new)
      self['id']=id
      self['eid']="#{layer}:#{id}"
      @cobj=type?(cobj,Command)
      @pre_proc=[] # Proc for Command Check (by User exec)
      @post_proc=[] # Proc for Command Issue (by User exec)
      @upd_proc=[] # Proc for Server Status Update (by User query)
      @save_proc=[] # Proc for Device Data Update (by Device response)
      @ver_color=6
      self['msg']=''
      Thread.abort_on_exception=true
      at_exit{@save_proc.each{|p| p.call}}
    end

    # Sync only (Wait for other thread)
    def exe(args)
      type?(args,Array)
      if args.empty?
        self['msg']=''
      else
        @pre_proc.each{|p| p.call(args)}
        self['msg']='OK'
        verbose("Sh/Exe","Command #{args} recieved")
        @cobj.setcmd(args).exe
        @post_proc.each{|p| p.call(args)}
      end
      self
    rescue
      self['msg']=$!.to_s
      raise $!
    ensure
      @upd_proc.each{|p| p.call}
    end

    def ext_client(host,port)
      extend(Client).ext_client(host,port)
    end

    def ext_server(port)
      extend(Server).ext_server(port)
    end

    def ext_shell(output={},pdb={})
      extend(Shell).ext_shell(output,pdb)
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
      verbose("UDP:Server/#{self.class}","Init/Server(#{self['id']}):#{port}",2)
      Thread.new{
        tc=Thread.current
        tc[:name]="Server Thread(#{self['eid']})"
        tc[:color]=9
        Thread.pass
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
      verbose("UDP:Client/#{self.class}","Init/Client(#{self['id']})#{host}:#{port}",6)
      self
    end

    # For client
    def exe(args)
      @cobj.setcmd(args).exe unless args.empty?
      @udp.send(JSON.dump(args),0,@addr)
      verbose("UDP:Client/#{self.class}","Send [#{args}]",6)
      res=@udp.recv(1024)
      verbose("UDP:Client/#{self.class}","Recv #{res}",6)
      update(JSON.load(res)) unless res.empty?
      self
    rescue
      self['msg']=$!.to_s
      raise $!
    ensure
      @upd_proc.each{|p| p.call}
    end
  end

  class ExeList < Hashx
    attr_reader :init_proc
    # shdom: Domain for Shared Command Groups
    def initialize(&new_proc)
      $opt||=GetOpts.new
      @new_proc=new_proc # For generate Exe (allows nil)
      @init_proc=[] # initialize exe at new key generated
    end

    def [](key)
      if key?(key)
        super
      else
        exe=self[key]=@new_proc.call(key)
        @init_proc.each{|p| p.call(exe)}
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
  end
end
