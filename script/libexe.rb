#!/usr/bin/env ruby
require 'libprompt'
require 'libcmdremote'

# Integrates Command and Status
# Provides Server and Client
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  # Device Execution Engine
  #  This instance will be assinged as @eobj in other classes
  class Exe
    include Msg
    attr_reader :layer, :id, :mode, :cobj, :stat, :sub_exe, :cfg,
                :pre_exe_procs, :post_exe_procs, :prompt_proc, :host, :port
    attr_accessor :sv_stat, :shell_input_procs, :shell_output_proc,
                  :server_input_proc, :server_output_proc
    #  cfg must have [:opt]
    #  atrb contains the parameter for each layer individually
    def initialize(spcfg, atrb = Hashx.new)
      @cfg = type?(spcfg, Config).gen(self).update(atrb)
      ___init_opt
      ___init_procs
      ___init_dbi
      @cobj = context_module('Index').new(@cfg)
      @layer = layer_name
    end

    # Sync only (Wait for other thread), never inherit
    # src can be 'user'(1),'shell'(1),'macro'(1),'local'(1),event'(2),'auto'(3)
    #  and 'udp:xxx'
    def exe(args, src = nil, pri = 1)
      type?(args, Array)
      src ||= 'local'
      verbose { _exe_text(args.inspect, src, pri) }
      @pre_exe_procs.each { |p| p.call(args, src) }
      msg = @cobj.set_cmd(args.dup).exe_cmd(src, pri).msg
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
      cmd_err { @cobj.view_dic }
    end

    #  Modes
    #   Shell  : ext_shell
    #       Add shell feature
    #   Remote : ext_remote
    #       Access via udp/html
    #   Local  : ext_local
    #       Manipulates memory
    #     Local Test   : ext_test
    #         Access to local file (read only)
    #     Local Driver : ext_driver
    #         Access to local file (R/W)
    #       Local log     : ext_local_log
    #           Add logging feature to local file
    #       Local server   : ext_server
    #           Add network command input feature

    def shell
      _ext_shell.shell
    end

    private

    # Option handling
    # Single Mode
    # none: test mode
    # -c: client mode
    # -e: drive mode
    # -s: test mode + server
    # -es: drive mode + server
    def _opt_mode
      @opt.cl? ? _ext_remote : _ext_local.opt_mode
    end

    def _ext_remote
      require 'libclient'
      return self if is_a?(Client)
      extend(Client).ext_remote
    end

    def _ext_local
      require 'libexelocal'
      extend(context_module('Local')).ext_local
    end

    def _ext_shell
      require 'libsh'
      return self if is_a?(Shell)
      extend(Shell).ext_shell
    end

    # Sub methods for Initialize
    def ___init_opt
      @cfg.check_keys(%i(opt))
      @opt = @cfg[:opt]
    end

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
    def ___init_dbi
      @dbi = type?(@cfg[:dbi], Dbx::Item)
      # dbi.pick already includes :command, :version
      @cfg.update(@dbi.pick(:id, :host, :port))
      @id = @dbi[:id]
    end

    def _dbi_pick(*ary)
      @cfg.update(@dbi.pick(*ary))
    end

    def _init_port(port_offset = 0)
      @host = @opt.host || @cfg[:host]
      @port = @cfg[:port].to_i + port_offset
      self
    end

    # Initialise Sub layer Exe
    #  used by Wat/Hex
    def _init_sub_exe
      se = @cfg[:sub_dic].get(@id)
      @sv_stat = se.sv_stat
      @cobj.add_rem(se.cobj.rem)
      @mode = se.mode
      @post_exe_procs.concat(se.post_exe_procs)
      se
    end
  end
end
