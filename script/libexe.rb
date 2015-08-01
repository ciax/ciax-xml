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
    attr_reader :layer,:id,:mode,:cobj,:pre_exe_procs,:post_exe_procs,:cfg,:prompt_proc
    attr_accessor :site_stat,:shell_input_procs,:shell_output_proc,:server_input_proc,:server_output_proc
    # attr contains the parameter for each layer individually (might have [:db])
    # cfg should have [:db] shared in the site (among layers)
    def initialize(id,cfg={},attr={})
      super()
      @cls_color=13
      @cfg=cfg.gen(self).update(attr)
      # layer is Frm,App,Wat,Hex,Mcr,Man
      @id=id
      cpath=class_path
      @mode=cpath.pop.upcase
      @layer=cpath.pop.downcase
      @site_stat=Prompt.new # Site Status shared among layers
      @pre_exe_procs=[] # Proc for Server Command (by User query)
      @post_exe_procs=[] # Proc for Server Status Update (by User query)
      self['msg']=''
      Thread.abort_on_exception=true
      verbose("initialize [#{@id}]")
    end

    # Sync only (Wait for other thread), never inherit
    def exe(args,src='local',pri=1)
      type?(args,Array)
      verbose("Command #{args} recieved")
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
      verbose(inspect)
    end

    def ext_client(host=nil,port=nil)
      extend(Client).ext_client(host,port)
    end

    def ext_server(port=nil)
      extend(Server).ext_server(port)
    end

    def ext_shell(als=nil)
      extend(Shell).ext_shell(als)
    end
  end
end
