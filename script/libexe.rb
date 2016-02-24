#!/usr/bin/ruby
require 'libserver'
require 'libclient'
require 'libprompt'
require 'libcmdremote'

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
    # cfg must have [:option]
    # attr contains the parameter for each layer individually (might have [:db])
    # cfg must have [:dbi] shared in the site (among layers)
    # @dbi will be set for Varx, @cfg[:dbi] will be set for Index
    # It is not necessarily the case that id and Config[:dbi][:id] is identical
    def initialize(id, cfg, attr = {})
      super()
      @cls_color = 13
      @id = id # Allows nil for Mcr::Man
      @cfg = type?(cfg, Config).gen(self).update(attr)
      # layer is Frm,App,Wat,Hex,Mcr,Man
      @layer = class_path.first.downcase
      # Proc for Server Command (by User query}
      @pre_exe_procs = [proc { verbose { 'Processing PreExeProcs' } }]
      # Proc for Server Status Update (by User query}
      @post_exe_procs = [proc { verbose { 'Processing PostExeProcs' } }]
      # Proc for program terminated
      @terminate_procs = [proc { verbose { 'Processing TerminateProcs' } }]
      Thread.abort_on_exception = true
      @cobj = Cmd::Remote::Index.new(@cfg)
    end

    # Sync only (Wait for other thread), never inherit
    # src can be 'local','shell','event','auto','udp:xxx'
    def exe(args, src = 'local', pri = 1)
      type?(args, Array)
      verbose { "Executing Command #{args} from '#{src}' as ##{pri}" }
      @pre_exe_procs.each { |p| p.call(args, src) }
      @sv_stat.rep(:msg, @cobj.set_cmd(args).exe_cmd(src, pri))
      @post_exe_procs.each { |p| p.call(args, src) }
      self
    rescue LongJump
      raise $ERROR_INFO
    rescue InvalidID
      @sv_stat.rep(:msg, $ERROR_INFO.to_s)
      raise $ERROR_INFO
    end

    def to_s
      @sv_stat.msg
    end

    def ext_shell
      extend(Shell).ext_shell
    end

    private

    def _init_prompt(sub_id = @id)
      # Site Status shared among layers
      if @cfg[:sub_list]
        @sub = @cfg[:sub_list].get(sub_id)
        @sv_stat = @sub.sv_stat
      else
        @sv_stat = Prompt.new(@cfg[:layer_type], @id)
      end
      @cfg[:sv_stat] = @sv_stat
    end

    def _init_dbi(id, ary = [])
      dbi = type?(@cfg[:db], CIAX::Db).get(id)
      @cfg.update(dbi.pick(ary))
      @id ||= dbi[:id]
      dbi
    end

    def _opt_mode
      # Option handling
      opt = @cfg[:option]
      if opt.cl?
        if opt[:s]
          opt[:e] ? ext_driver : ext_test
          ext_server
        else
          ext_client
        end
      else
        opt[:e] ? ext_driver : ext_test
        ext_server if opt[:s]
      end
      self
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

    def ext_server
      return self if @mode == 'CL'
      @mode += ':SV'
      extend(Server).ext_server
    end
  end
end
