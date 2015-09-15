#!/usr/bin/ruby
require "libserver"
require "libclient"
require "libprompt"
require "libremote"

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
    def initialize(id,cfg,attr={})
      super()
      @cls_color=13
      @cfg=type?(cfg,Config).gen(self).update(attr)
      # layer is Frm,App,Wat,Hex,Mcr,Man
      @id=id
      @layer=class_path.first.downcase
      @site_stat=Prompt.new # Site Status shared among layers
      @pre_exe_procs=[] # Proc for Server Command (by User query)
      @post_exe_procs=[] # Proc for Server Status Update (by User query)
      @terminate_procs=[] # Proc for program terminated
      Thread.abort_on_exception=true
      verbose("initialize [#{@id}]")
      @dbi=@cfg[:dbi]=type?(@cfg[:db].get(id),Dbi) if @cfg.key?(:db)
      @cobj=Remote::Index.new(@cfg)
    end

    # Sync only (Wait for other thread), never inherit
    def exe(args,src='local',pri=1)
      type?(args,Array)
      verbose("Command #{args} recieved")
      @pre_exe_procs.each{|p| p.call(args,src)}
      @site_stat.msg(@cobj.set_cmd(args).exe_cmd(src,pri))
    rescue LongJump
      raise $!
    rescue InvalidID
      @site_stat.msg($!.to_s)
      raise $!
    ensure
      @post_exe_procs.each{|p| p.call(args,src)}
    end

    def ext_test
      @mode='TEST'
      self
    end

    def ext_drv
      @mode='DRV'
      self
    end

    def ext_client
      @mode='CL'
      extend(Client).ext_client
    end


    def ext_server
      extend(Server).ext_server
    end

    def ext_shell
      extend(Shell).ext_shell
    end
  end
end
