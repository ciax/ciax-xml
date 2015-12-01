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
  # Device Execution Engine
  class Exe
    include Msg
    attr_reader :layer, :id, :mode, :cobj, :stat, :sub, :cfg,
                :pre_exe_procs, :post_exe_procs, :prompt_proc, :host, :port
    attr_accessor :sv_stat, :shell_input_procs, :shell_output_proc,
                  :server_input_proc, :server_output_proc
    # attr contains the parameter for each layer individually (might have [:db])
    # cfg should have [:db] shared in the site (among layers)
    def initialize(id, cfg, attr = {})
      super()
      @cls_color = 13
      @cfg = type?(cfg, Config).gen(self).update(attr)
      # layer is Frm,App,Wat,Hex,Mcr,Man
      @dbi = @cfg[:dbi] = type?(@cfg[:db].get(id), Dbi) if @cfg.key?(:db)
      @id = id || @dbi[:id]
      @layer = class_path.first.downcase
      # Site Status shared among layers
      @sv_stat = Prompt.new(@cfg[:layer_type], @id)
      # Proc for Server Command (by User query}
      @pre_exe_procs = [proc { verbose { 'Processing PreExeProcs' } }]
      # Proc for Server Status Update (by User query}
      @post_exe_procs = [proc { verbose { 'Processing PostExeProcs' } }]
      # Proc for program terminated
      @terminate_procs = [proc { verbose { 'Processing TerminateProcs' } }]
      Thread.abort_on_exception = true
      verbose { "initialize [#{@id}]" }
      @cobj = Remote::Index.new(@cfg)
      @host = OPT.host
    end

    # Sync only (Wait for other thread), never inherit
    # src can be 'local','shell','auto','udp:xxx'
    def exe(args, src = 'local', pri = 1)
      type?(args, Array)
      verbose { "Executing Command #{args} from '#{src}' as ##{pri}" }
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
      @sv_stat.msg
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
