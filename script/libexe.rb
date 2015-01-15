#!/usr/bin/ruby
require "socket"
require "readline"
require "libextcmd"

# Provide Server,Client
# Integrate Command,Status
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  class Prompt < Hashx
    attr_reader :db
    def initialize
      super()
      @db={}
    end

    def add_db(db={})
      @db.update(type?(db,Hash))
      self
    end

    # Pick up and merge to self data, return other data
    def pick(input)
      hash=input.dup
      @db.keys.each{|k|
        self[k]=hash.delete(k) if hash[k]
      }
      hash
    end

    def to_s
      @db.map{|k,v| v if self[k] }.join('')
    end
  end

  class Exe < Hashx # Having server status {id,msg,...}
    attr_reader :layer,:id,:mode,:pre_exe_procs,:post_exe_procs,:cobj,:output,:prompt_proc
    attr_accessor :site_stat,:shell_input_proc,:shell_output_proc,:server_input_proc,:server_output_proc
    # block gives command line convert
    def initialize(layer,id,cobj=Command.new)
      super()
      @id=id
      @layer=layer
      @cobj=type?(cobj,Command)
      @pre_exe_procs=[] # Proc for Server Command (by User query)
      @post_exe_procs=[] # Proc for Server Status Update (by User query)
      @site_stat=Prompt.new # Status shared by all layers of the site
      @cls_color||=7
      @pfx_color||=9
      @output={}
      self['msg']=''
      @server_input_proc=proc{|line|
        begin
          JSON.load(line)
        rescue JSON::ParserError
          raise "NOT JSON"
        end
      }
      @server_output_proc=proc{ merge(@site_stat).to_j }
      @shell_input_proc=proc{|args|
        if (cmd=args.first) && cmd.include?('=')
          args=['set']+cmd.split('=')
        end
        args
      }
      @shell_output_proc=proc{ self['msg'].empty? ? @output : self['msg'] }
      Thread.abort_on_exception=true
      verbose("Exe","initialize")
    end

    # Sync only (Wait for other thread), never inherit
    def exe(args,src='local',pri=1)
      type?(args,Array)
      verbose("Exe","Command #{args} recieved")
      @pre_exe_procs.each{|p| p.call(args)}
      self['msg']=@cobj.set_cmd(args).exe_cmd(src,pri)
      self
    rescue LongJump
      raise $!
    rescue InvalidID
      self['msg']=$!.to_s
      raise $!
    ensure
      @post_exe_procs.each{|p| p.call(self)}
    end

    def ext_client(host,port)
      extend(Client).ext_client(host,port)
    end

    def ext_server(port)
      extend(Server).ext_server(port)
    end

    def ext_shell
      extend(Shell).ext_shell
    end
  end

  module Server
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # JSON expression of server stat will be sent.
    def ext_server(port)
      @mode='SV'
      verbose("UDP:Server","Initialize(#@id):#{port}")
      udp=UDPSocket.open
      udp.bind("0.0.0.0",port.to_i)
      ThreadLoop.new("Server(#@layer:#@id)",9){
        IO.select([udp])
        line,addr=udp.recvfrom(4096)
        line.chomp!
        rhost=Addrinfo.ip(addr[2]).getnameinfo.first
        verbose("Exe:Server","Valid Commands #{@cobj.valid_keys}")
        verbose("UDP:Server","Recv:#{line} is #{line.class}")
        begin
          exe(@server_input_proc.call(line),"udp:#{rhost}")
        rescue InvalidCMD
          self['msg']="INVALID"
        rescue
          self['msg']=$!.to_s
          errmsg
        end
        send_str=@server_output_proc.call
        verbose("UDP:Server","Send:#{send_str}")
        udp.send(send_str,0,addr[2],addr[1])
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
      verbose("UDP:Client","Initialize(#@id):#{host}:#{port}")
      @cobj.svdom.set_proc{|ent|
        args=ent.id.split(':')
        @udp.send(JSON.dump(args),0,@addr) # Address family not supported by protocol -> see above
        verbose("UDP:Client","Send [#{args}]")
        res=@udp.recv(1024)
        verbose("UDP:Client","Recv #{res}")
        update(@site_stat.pick(JSON.load(res))) unless res.empty?
        self['msg']
      }
      self
    end
  end
end
