#!/usr/bin/ruby
require 'libserver'
require 'libclient'
require 'libprompt'
require 'libremote'

# Provide Server,Client
# Integrate Command,Status
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  class Exe < Hashx # Having server status {id,msg,...}
    attr_reader :layer, :id, :mode, :cobj, :stat, :sub, :pre_exe_procs, :post_exe_procs, :cfg, :prompt_proc, :host, :port
    attr_accessor :sv_stat, :shell_input_procs, :shell_output_proc, :server_input_proc, :server_output_proc
    # attr contains the parameter for each layer individually (might have [:db])
    # cfg should have [:db] shared in the site (among layers)
    def initialize(id, cfg = Config.new, attr = {})
      super()
      @cls_color = 13
      @cfg = type?(cfg, Config).gen(self).update(attr)
      # layer is Frm,App,Wat,Hex,Mcr,Man
      @id = id
      @layer = class_path.first.downcase
      @sv_stat = Prompt.new # Site Status shared among layers
      @pre_exe_procs = [proc { verbose { 'Processing PreExeProcs' } }] # Proc for Server Command (by User query}
      @post_exe_procs = [proc { verbose { 'Processing PostExeProcs' } }] # Proc for Server Status Update (by User query}
      @terminate_procs = [proc { verbose { 'Processing TerminateProcs' } }] # Proc for program terminated
      Thread.abort_on_exception = true
      verbose { "initialize [#{@id}]" }
      @dbi = @cfg[:dbi] = type?(@cfg[:db].get(id), Dbi) if @cfg.key?(:db)
      @cobj = Remote::Index.new(@cfg)
      @host = OPT.host
    end

    # Sync only (Wait for other thread), never inherit
    # src can be 'local','shell','auto','udp:xxx'
    def exe(args, src = 'local', pri = 1)
      type?(args, Array)
      verbose { "Command #{args} recieved from '#{src}' as ##{pri}" }
      @pre_exe_procs.each { |p| p.call(args, src) }
      @sv_stat.msg(@cobj.set_cmd(args).exe_cmd(src, pri))
      @post_exe_procs.each { |p| p.call(args, src) }
      self
    rescue LongJump
      raise $ERROR_INFO
    rescue InvalidID
      @sv_stat.msg($ERROR_INFO.to_s)
      raise $ERROR_INFO
    end

    def to_s
      @sv_stat['msg']
    end

    def ext_server
      @mode += ':SV'
      extend(Server).ext_server
    end

    def ext_shell
      extend(Shell).ext_shell
    end

    private

    def opt_mode
      # Option handling
      if OPT.sv?
        ext_driver
      elsif OPT.cl?
        ext_client
      else
        ext_test
      end
    end

    def ext_test
      @mode = 'TEST'
      self
    end

    def ext_driver
      @mode = 'DRV'
      self
    end

    def ext_client
      @mode = 'CL'
      @stat.ext_http(@host)
      @pre_exe_procs << proc { @stat.upd }
      extend(Client).ext_client
    end
  end
end
