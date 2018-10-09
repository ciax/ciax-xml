#!/usr/bin/ruby
require 'libprompt'
require 'libcmdremote'

# Integrates Command and Status
# Provides Server and Client
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
    #  cfg must have [:opt]
    #  atrb contains the parameter for each layer individually
    def initialize(super_cfg, atrb = Hashx.new)
      @cfg = type?(super_cfg, Config).gen(self).update(atrb)
      @cfg.check_keys(%i(opt))
      @opt = @cfg[:opt]
      ___init_procs
      @cobj = context_module('Index').new(@cfg)
      @layer = layer_name
    end

    # Sync only (Wait for other thread), never inherit
    # src can be 'user'(1),'shell'(1),'macro'(1),'local'(1),event'(2),'auto'(3)
    #  and 'udp:xxx'
    def exe(args, src = nil, pri = 1)
      type?(args, Array)
      src ||= 'local'
      verbose { "Executing Command #{args} from '#{src}' as ##{pri}" }
      @pre_exe_procs.each { |p| p.call(args, src) }
      msg = @cobj.set_cmd(args).exe_cmd(src, pri).msg
      @post_exe_procs.each { |p| p.call(args, src, msg) }
      self
    rescue LongJump, InvalidARGS
      @sv_stat.seterr
      raise
    end

    def to_s
      @sv_stat.msg
    end

    def no_cmd
      cmd_err @cobj.view_list
    end

    #  Modes
    #   Test           : ext_test
    #       No stored data access
    #   Remote client  : ext_client
    #       Access via udp/html
    #   Local client   : ext_local
    #        Access to local file (read only)
    #     Local processor: ext_local_proc
    #         Processing with file (read only)
    #       Local save     : ext_local_save
    #           Add data saving feature to local file
    #       Local server   : ext_local_server
    #           Add network feature for command input
    #   Shell          : ext_shell
    #       Add shell feagure

    def ext_shell
      require 'libsh'
      @cobj.rem.sys.add_empty
      extend(context_module('Shell')).ext_shell
    end

    # No save any data
    def ext_local_test
      @mode = 'TEST'
      _ext_local
    end

    # Generate and Save Data
    def ext_local_driver
      @mode = 'DRV'
      extend(context_module('Driver')).ext_local_driver
      _ext_local
    end

    # Load Data
    def ext_client
      require 'libclient'
      extend(Client).ext_client
    end

    # UDP Listen
    def ext_local_server
      require 'libserver'
      @cobj.rem.sys.add_empty
      extend(Server).ext_local_server
    end

    private

    # Local operation included in ext_local_test, ext_local_driver
    # (non_client)
    def _ext_local
      @post_exe_procs << proc { |_args, _src, msg| @sv_stat.repl(:msg, msg) }
      self
    end

    # Sub methods for Initialize
    def ___init_procs
      # Proc for Server Command (by User query}
      @pre_exe_procs = [proc { verbose { 'Processing PreExeProcs' } }]
      # Proc for Server Status Update (by User query}
      @post_exe_procs = [proc { verbose { 'Processing PostExeProcs' } }]
      # Proc for program terminated
      @terminate_procs = [proc { verbose { 'Processing TerminateProcs' } }]
    end

    # For external command
    #  @cfg must have [:dbi] shared in the site (among layers)
    #  @dbi will be set for Varx, @cfg[:dbi] will be set for Index
    #  It is not necessarily the case that id and Config[:dbi][:id] is identical
    def _init_dbi2cfg(ary = [])
      dbi = type?(@cfg[:dbi], CIAX::Dbi)
      # dbi.pick already includes :command, :version
      @cfg.update(dbi.pick(ary + %i(id host port)))
      @id = dbi[:id]
      dbi
    end

    def _init_net
      @host = @opt.host || @cfg[:host]
      @port = @cfg[:port]
      self
    end

    # Single Mode
    # none: test mode
    # -c: client mode
    # -e: drive mode
    # -s: test mode + server
    # -es: drive mode + server
    def _opt_mode
      # Option handling
      return ext_client if @opt.cl?
      @opt.drv? ? ext_local_driver : ext_local_test
      ext_local_server if @opt.sv?
      self
    end
  end
end
