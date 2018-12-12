#!/usr/bin/ruby
require 'readline'
require 'libthreadx'

module CIAX
  # Device Execution Engine
  class Exe
    # Provide Shell related modules
    # Add Shell Command (by Shell extension)
    module Shell
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      # Separate initialize part because shell() could be called multiple times
      def ext_local_shell
        @cobj.rem.sys.add_empty
        @cfg[:output] = @stat
        ___init_sh_procs
        @cobj.loc.add_shell
        @cobj.loc.add_jump
        self
      end

      # Convert Shell input from "x=n" to "set x n"
      def input_conv_set
        @shell_input_procs << proc do |args|
          if args[0] && args[0].include?('=')
            ['set'] + args.shift.split('=') + args
          else
            args
          end
        end
        self
      end

      # Substitute command from number to value
      def input_conv_num
        @shell_input_procs << proc do |args|
          args[0] = yield(args[0].to_i) if /^[0-9]+$/ =~ args[0]
          args
        end
        self
      end

      def prompt
        str = "#{@layer}:#{@id}"
        str += "(#{@mode})" if @mode
        str += @prompt_proc.call if @prompt_proc
        str + '>'
      end

      # * 'shell' is separated from 'ext_local_shell',
      #    because it will repeat being invoked and exit multiple times.
      # * '^D' gives interrupt
      def shell
        verbose { "Shell(#{@id})" }
        ___init_readline
        loop do
          line = ___input || break
          ___exe(___cmds(line))
          puts @shell_output_proc.call
        end
        @terminate_procs.inject(self) { |a, e| e.call(a) }
        Msg.msg('Quit Shell', 3)
      end

      private

      def ___init_sh_procs
        @shell_input_procs = [] # proc takes args(Array)
        @shell_output_proc ||= proc do
          if @sv_stat.msg.empty?
            @cfg[:output].to_s
          else
            @sv_stat.msg
          end
        end
        @prompt_proc = proc { @sv_stat.to_s }
      end

      def ___init_readline
        Readline.completion_proc = proc { |word|
          (@cobj.valid_keys + @cobj.valid_pars).grep(/^#{word}/)
        }
      end

      def ___input
        verbose { "Threads\n#{Threadx.list}" }
        verbose { "Valid Commands #{@cobj.valid_keys}" }
        inp = Readline.readline(prompt, true) || 'interrupt'
        /^q/ =~ inp ? nil : inp
      rescue Interrupt
        'interrupt'
      end

      def ___cmds(line)
        cmds = line.split(';')
        cmds = [''] if cmds.empty?
        cmds
      end

      def ___exe(cmds)
        cmds.each { |s| exe(___input_conv(s), 'shell') }
      rescue UserError
        nil
      rescue ServerError
        show_err
      end

      def ___input_conv(token)
        @shell_input_procs.inject(token.split(' ')) do |args, proc|
          proc.call(args)
        end
      end
    end
  end
end
# !/usr/bin/ruby
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
    #   Shell  : ext_local_shell
    #       Add shell feature
    #   Remote : ext_remote_client
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

    # UDP Listen
    def run
      return self if @opt.cl?
      require 'libserver'
      return self if is_a?(Server)
      extend(Server).ext_local_server
    end

    private

    # Local operation included in ext_local_test, ext_local_driver
    # (non_client)
    def _ext_local
      @post_exe_procs << proc { |_args, _src, msg| @sv_stat.repl(:msg, msg) }
      self
    end

    def _ext_local_shell
      require 'libsh'
      return self if is_a?(Shell)
      extend(Shell).ext_local_shell
    end

    # No save any data
    def _ext_local_test
      @mode = 'TEST'
      self
    end

    # Generate and Save Data
    def _ext_local_driver
      @mode = 'DRV'
      self
    end

    # Load Data
    def _ext_remote_client
      require 'libclient'
      return self if is_a?(Client)
      extend(Client).ext_remote_client
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
      return _ext_remote_client if @opt.cl?
      _ext_local
      @opt.drv? ? _ext_local_driver : _ext_local_test
    end
  end
end
