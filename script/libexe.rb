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
    # atrb contains the parameter for each layer individually (might have [:db])
    # cfg must have [:dbi] shared in the site (among layers)
    # @dbi will be set for Varx, @cfg[:dbi] will be set for Index
    # It is not necessarily the case that id and Config[:dbi][:id] is identical
    def initialize(id, cfg, atrb = Hashx.new)
      @cfg = type?(cfg, Config).gen(self).update(atrb)
      @id = id || @cfg[:id] # Allows nil for Mcr::Man
      # layer is Frm,App,Wat,Hex,Mcr,Man
      @layer = class_path.first.downcase
      _init_procs
      Thread.abort_on_exception = true
      @cobj = Cmd::Remote::Index.new(@cfg)
    end

    # Sync only (Wait for other thread), never inherit
    # src can be 'user'(1),'shell'(1),'macro'(1),'local'(1),event'(2),'auto'(3)
    #  and 'udp:xxx'
    def exe(args, src = nil, pri = 1)
      type?(args, Array)
      src ||= (@cfg[:src] || 'local')
      verbose { "Executing Command #{args} from '#{src}' as ##{pri}" }
      @pre_exe_procs.each { |p| p.call(args, src) }
      msg = @cobj.set_cmd(args).exe_cmd(src, pri).msg
      @post_exe_procs.each { |p| p.call(args, src, msg) }
      self
    rescue LongJump, InvalidARGS
      @sv_stat.repl(:msg, $ERROR_INFO.to_s)
      raise $ERROR_INFO
    end

    def to_s
      @sv_stat.msg
    end

    def ext_shell
      extend(Shell).ext_shell
    end

    private

    def _init_procs
      # Proc for Server Command (by User query}
      @pre_exe_procs = [proc { verbose { 'Processing PreExeProcs' } }]
      # Proc for Server Status Update (by User query}
      @post_exe_procs = [proc { verbose { 'Processing PostExeProcs' } }]
      # Proc for program terminated
      @terminate_procs = [proc { verbose { 'Processing TerminateProcs' } }]
    end

    def _init_dbi(id, ary = [])
      dbi = type?(@cfg[:db], CIAX::Db).get(id)
      # dbi.pick already includes :command, :version
      @cfg.update(dbi.pick(ary))
      @id ||= dbi[:id]
      dbi
    end

    # Single Mode
    # none: test mode
    # -c: client mode
    # -e: drive mode
    # -s: test mode + server
    # -es: drive mode + server
    def _opt_mode
      # Option handling
      opt = @cfg[:option]
      return ext_client if opt.cl? && !opt.drv? # Client only
      opt[:e] ? ext_driver : ext_test
      ext_server if opt[:s]
      self
    end

    def ext_test
      @mode = 'TEST'
      _non_client
      self
    end

    def ext_driver
      @mode = 'DRV'
      _non_client
      self
    end

    def ext_client
      @mode = 'CL'
      extend(Client).ext_client
    end

    def ext_server
      return self if @mode == 'CL'
      @mode += ':SV'
      extend(Server).ext_server
    end

    def _non_client
      @post_exe_procs << proc { |_args, _src, msg| @sv_stat.repl(:msg, msg) }
      self
    end
  end
end
