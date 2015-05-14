#!/usr/bin/ruby
require "socket"
require "readline"
require "libextcmd"

# Provide Server,Client
# Integrate Command,Status
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  $layers={}
  class Exe < Hashx # Having server status {id,msg,...}
    attr_reader :layer,:id,:mode,:cobj,:pre_exe_procs,:post_exe_procs,:cfg,:output,:prompt_proc
    attr_accessor :shell_input_proc,:shell_output_proc,:server_input_proc,:server_output_proc
    # inter_cfg contains the parameter shared among layers for the site, which are taken over from list level
    # attr contains the parameter for each layer individually (might have [:db])
    # inter_cfg should have ['id'] and might have [:site_stat] shared in the site (among layers)
    def initialize(id,inter_cfg={},attr={})
      super()
      # layer is Frm,App,Wat,Hex,Mcr,Man
      @id=id
      cpath=class_path
      @mode=cpath.pop.upcase
      @layer=cpath.pop.downcase
      @site_stat=(type?(inter_cfg,Hash)[:site_stat]||=Prompt.new) # Status shared by all layers of the site
      @cfg=Config.new("#{@layer}_exe",inter_cfg).update(attr)
      @cfg[@layer]=self
      @cfg['layer']=@layer
      @cobj=local_class('Command').new(@cfg)
      @pre_exe_procs=[] # Proc for Server Command (by User query)
      @post_exe_procs=[] # Proc for Server Status Update (by User query)
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
      @shell_output_proc=proc{ @output }
      @prompt_proc=proc{ @site_stat.to_s }
      Thread.abort_on_exception=true
      verbose("Exe","initialize [#{@id}]")
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
      verbose("Exe",inspect)
    end

    def ext_client(host,port)
      extend(Client).ext_client(host,port)
    end

    def ext_server(port)
      extend(Server).ext_server(port)
    end

    def ext_shell(als=nil)
      extend(Shell).ext_shell(als)
    end
  end

  module Server
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # JSON expression of server stat will be sent.
    def ext_server(port)
      verbose("UDP:Server","Initialize [#@id:#{port}]")
      @cobj.add_nil
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
      host||='localhost'
      @site_stat.add_db('udperr' => 'x')
      @udp=UDPSocket.open()
      verbose("UDP:Client","Initialize [#@id/#{host}:#{port}]")
      @addr=Socket.pack_sockaddr_in(port.to_i,host)
      @cobj.svdom.set_proc{|ent|
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
        self[k]= hash[k] ? hash.delete(k) : false
      }
      hash
    end

    def to_s
      verbose("Shell",inspect)
      @db.map{|k,v| v if self[k] }.join('')
    end
  end
end
