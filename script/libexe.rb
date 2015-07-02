#!/usr/bin/ruby
require "libserver"
require "libclient"
require "libprompt"
require "libcommand"

# Provide Server,Client
# Integrate Command,Status
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  class Exe < Hashx # Having server status {id,msg,...}
    attr_reader :layer,:id,:mode,:cobj,:pre_exe_procs,:post_exe_procs,:cfg,:output,:prompt_proc
    attr_accessor :site_stat,:shell_input_proc,:shell_output_proc,:server_input_proc,:server_output_proc
    # attr contains the parameter for each layer individually (might have [:db])
    # cfg should have [:db] shared in the site (among layers)
    def initialize(id,cfg={},attr={})
      super()
      @cfg=cfg.gen(self).update(attr)
      # layer is Frm,App,Wat,Hex,Mcr,Man
      @id=id
      cpath=class_path
      @mode=cpath.pop.upcase
      @layer=cpath.pop.downcase
      @site_stat=Prompt.new # Site Status shared among layers
      @pre_exe_procs=[] # Proc for Server Command (by User query)
      @post_exe_procs=[] # Proc for Server Status Update (by User query)
      @cls_color||=7
      @pfx_color||=9
      @output={}
      self['msg']=''
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
