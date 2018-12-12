#!/usr/bin/ruby
require 'liblist'
require 'libmcrexe'
require 'libmanproc'

module CIAX
  module Mcr
    # List for Running Macro
    class List < List
      attr_reader :cfg, :sub_list, :man
      # @cfg should have [:sv_stat]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        @sub_list = @cfg[:dev_list] = Wat::List.new(@cfg)
        @man = Man.new(@cfg).ext_local_processor(self)
      end

      def get(id)
        return @man if id == 'man'
        ent = super
        @man.sv_stat.repl(:sid, id)
        ent
      end

      # For adding Exe
      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ment) # returns Exe
        mobj = Exe.new(ment) { |e| add(e) }
        put(mobj.id, mobj.run)
        @man.stat.push(mobj.stat)
        mobj
      end

      def interrupt
        _list.each(&:interrupt)
        self
      end

      def run
        @sub_list.run
        @man.run
        ___arc_refresh
        ___web_cmdlist
        self
      end

      private

      def ___arc_refresh
        verbose { 'Initiate Record Archive' }
        Threadx::Fork.new('RecArc', 'mcr', @id) do
          @man.stat.clear.refresh
        end
      end

      # Making Command List JSON file for WebApp
      def ___web_cmdlist
        verbose { 'Initiate JS Command List' }
        dbi = @cfg[:dbi]
        jl = Hashx.new(port: @port, commands: dbi.list, label: dbi.label)
        IO.write(vardir('json') + 'mcr_conf.js', 'var config = ' + jl.to_j)
      end

      # Mcr::List specific Shell
      module Shell
        include CIAX::List::Shell

        def ext_local_shell
          super
          @cfg[:jump_mcr] = @jumpgrp
          @current = 'man'
          @jumpgrp.add_item(@current, 'manager')
          _list.each_value { |mobj| __set_jump(mobj) }
          self
        end

        def add(ment)
          __set_jump(super)
        end

        private

        def __set_jump(mobj)
          @current = type?(mobj, CIAX::Exe).id
          @jumpgrp.add_item(mobj.id, mobj.cfg[:cid])
          mobj
        end
      end

      class Jump < LongJump; end

      if __FILE__ == $PROGRAM_NAME
        ConfOpts.new('[id]', options: 'cehlns') do |cfg|
          List.new(cfg).shell
        end
      end
    end
  end
end
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
# !/usr/bin/ruby
require 'libexe'
require 'libseq'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Exe < Exe
      attr_reader :thread, :seq
      def initialize(super_cfg, atrb = Hashx.new, &submcr_proc)
        super
        verbose { 'Initiate New Macro' }
        ___init_cmd
        ___init_seq(submcr_proc)
        @sv_stat = type?(@cfg[:sv_stat], Prompt)
        ___init_rem_sys
        _ext_local
        @mode = @opt.drv? ? 'DRV' : 'TEST'
      end

      def interrupt
        @thread.raise(Interrupt)
        self
      end

      def run
        @thread = Msg.type?(@seq.fork, Threadx::Fork)
        self
      end

      # Mode Extention by Option
      def ext_local_shell
        extend(Shell).ext_local_shell
        @prompt_proc = proc { @sv_stat.to_s + optlist(@int.valid_keys) }
        @cobj.loc.add_view
        self
      end

      private

      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        @int = rem.add_int
        @cfg[:valid_keys] = @int.valid_keys.clear
      end

      def ___init_seq(submcr_proc)
        @seq = Sequencer.new(@cfg, &submcr_proc)
        @id = @seq.id
        @int.def_proc { |ent| @seq.reply(ent.id) }
        @stat = @seq.record
      end

      def ___init_rem_sys
        @cobj.get('interrupt').def_proc { interrupt }
        @cobj.get('nonstop').def_proc { @sv_stat.up(:nonstop) }
        @cobj.get('interactive').def_proc { @sv_stat.dw(:nonstop) }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'eldnr') do |cfg, args|
        ent = Index.new(cfg).add_rem.add_ext.set_cmd(args)
        Exe.new(ent).run.shell
      end
    end
  end
end
# !/usr/bin/ruby
require 'libsh'
require 'libman'
require 'libreclist'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      private

      def _ext_local_shell
        return self if is_a?(Shell)
        extend(Shell).ext_local_shell
      end
      # Macro Shell
      module Shell
        include Exe::Shell
        # cfg should have [:jump_groups]
        def ext_local_shell
          super
          verbose { 'Initiate Mcr Shell' }
          ___init_stat
          ___init_prompt
          ___init_page_cmd
          ___init_rank_cmd(@cobj.loc.add_view)
          self
        end

        private

        def ___init_stat
          @view = RecList.new(@stat, @id, @cobj.rem.int).ext_view
          @opt.cl? ? @view.ext_remote(@host) : @view.ext_local
          @stat.push_proc = proc { |rec| @view.push(rec) }
          @cfg[:output] = @view
        end

        def ___init_prompt
          # @view will be switched among Whole List or Records
          # Setting @par will switch the Record
          @prompt_proc = proc do
            str = @sv_stat.to_s + "[#{@view.upd.current_idx}]"
            str << optlist((@view.current_rec || {})[:option])
          end
        end

        def ___init_page_cmd
          page = @cobj.loc.add_page
          page.get('last').def_proc do |ent|
            @view.get_arc(ent.par[0]).upd
          end
          page.get('cl').def_proc do
            @view.flush.upd
          end
          ___init_conv
        end

        def ___init_rank_cmd(view)
          return unless @cobj.rem.ext
          view.add_item('dig', 'Show more Submacros').def_proc do
            @cobj.rem.ext.rankup
            @cobj.error
          end
          view.add_item('hide', 'Hide Submacros').def_proc do
            @cobj.rem.ext.rank(0)
            @cobj.error
          end
        end

        # Set Current ID by number
        def ___init_conv
          # i should be number
          input_conv_num do |i|
            if i > 10_000
              i.to_s
            else
              @view.sel(i)
              nil
              # nil:no command -> show record
            end
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cnlr') do |cfg|
        Man.new(cfg).shell
      end
    end
  end
end
