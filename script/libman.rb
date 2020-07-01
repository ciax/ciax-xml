#!/usr/bin/env ruby
require 'libexe'
require 'libmcrcmd'
require 'librecarclist'
require 'libwatdic'

module CIAX
  # Macro Layer
  module Man
    # Macro Manager/Manipulator
    #  Features
    #   *Test/Driver
    #    -Generate Mcr::Exe and Push to ExeDic
    #   *Front End
    #    -Switch to Exe(Shell) if Driver mode
    #    -Show List of picked Record in Archive besides Exes
    #    -Pseudo Shell for Archive Records/Remote Exe
    #   *Server
    #    -Accept Mcr generate command
    #    -Accept Manipulation command to individual Exes with ID
    #  Commands
    #   *Mcr Generation Command (gencmd)
    #   *Mcr Manipulation command (mancmd)
    class Exe < CIAX::Exe
      def initialize(spcfg, atrb = Hashx.new)
        super
        verbose { 'Initiate Manager (option:' + @opt.keys.join + ')' }
        # id = nil -> taken by ARGV
        # pick already includes :command, :version
        _dbi_pick(:sites)
        _init_port
        ___init_stat
        ___init_cmd
        _opt_mode
      end

      private

      def _ext_remote
        super
        _remote_sv_stat
        _remote_stat
        self
      end

      # Overridden by libmansh
      def _ext_shell
        super
        @cobj.loc.add_view
        @cfg[:output] = RecArc::List.new(@stat)
        @prompt_proc = proc do
          @int_par.def_par
          ''
        end
        self
      end

      def ___init_stat
        @stat = (@cfg[:rec_arc] ||= RecArc.new)
        @sv_stat = (@cfg[:sv_stat] ||= Prompt.new(@id, @opt))
      end

      # Initiate for all mode
      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        @int_par = rem.add_int.pars.add_enum(@sv_stat.get(:list)).last
        rem.add_ext
      end
      # Local mode
      module Local
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        private

        def _ext_driver
          super
          @cfg[:cid] = 'manager'
          @mode = 'DRY' if @opt.dry?
          @cobj.get('nonstop').def_proc { sv_stat.up(:nonstop) }
          @cobj.get('interactive').def_proc { sv_stat.dw(:nonstop) }
          ___init_pre_exe
          ___init_log
          self
        end

        def ___init_pre_exe
          @pre_exe_procs << proc do
            @sv_stat.repl(:sid, '')
            @sv_stat.flush(:run).cmt if @sv_stat.get(:list).empty?
          end
        end

        def ___init_log
          return unless @opt.mcr_log?
          @cobj.rem.ext_input_log
          @sv_stat.ext_local.ext_log
        end
      end
    end
    if $PROGRAM_NAME == __FILE__
      Mcr::Conf.new('[proj] [cmd] (par)', options: 'cedhlnr') do |cfg|
        Exe.new(cfg)
      end.cui
    end
  end
end
