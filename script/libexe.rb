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
    attr_reader :layer, :id, :mode, :cobj, :stat, :sub, :cfg,
                :pre_exe_procs, :post_exe_procs, :prompt_proc, :host, :port
    attr_accessor :sv_stat, :shell_input_procs, :shell_output_proc,
                  :server_input_proc, :server_output_proc
    #  cfg must have [:opt]
    #  atrb contains the parameter for each layer individually
    def initialize(spcfg, atrb = Hashx.new)
      @cfg = type?(spcfg, Config).gen(self).update(atrb)
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
      cmd_err @cobj.view_dic
    end

    #  Modes
    #   Shell  : ext_local_shell
    #       Add shell feature
    #   Remote : ext_remote
    #       Access via udp/html
    #   Local  : ext_local
    #       Manipulates memory
    #     Local Test   : ext_local_test
    #         Access to local file (read only)
    #     Local Driver : ext_local_driver
    #         Access to local file (R/W)
    #       Local log     : ext_local_log
    #           Add logging feature to local file
    #       Local server   : ext_local_server
    #           Add network command input feature

    def shell
      _ext_local_shell.shell
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
      extend(context_module('Local')).ext_local
    end

    def _ext_local_shell
      require 'libsh'
      return self if is_a?(Shell)
      extend(Shell).ext_local_shell
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
      dbi = type?(@cfg[:dbi], Dbx::Item)
      # dbi.pick already includes :command, :version
      @cfg.update(dbi.pick(*ary, :id, :host, :port))
      @id = dbi[:id]
      dbi
    end

    def _init_net
      @host = @opt.host || @cfg[:host]
      @port = @cfg[:port]
      self
    end

    # Local mode
    module Local
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      # Local operation included in ext_local_test, ext_local_driver
      # (non_client)
      def ext_local
        @stat.ext_local.ext_file
        @post_exe_procs << proc { |_args, _src, msg| @sv_stat.repl(:msg, msg) }
        self
      end

      # UDP Listen
      def run
        return self if @opt.cl?
        require 'libserver'
        return self if is_a?(Server)
        extend(Server).ext_local_server
      end

      # Option handling
      def opt_mode
        @opt.drv? ? _ext_local_driver : _ext_local_test
      end

      private

      # No save any data
      def _ext_local_test
        @mode = 'TEST'
        self
      end

      # Generate and Save Data
      def _ext_local_driver
        @mode = 'DRV'
        @stat.ext_save
        self
      end
    end
  end
end
