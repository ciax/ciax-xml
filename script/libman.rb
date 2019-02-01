#!/usr/bin/env ruby
require 'libexe'
require 'libmcrcmd'
require 'librecview'
require 'libwatdic' # deprecated

module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager/Manipulator
    #  Features
    #   *Test/Driver
    #    -Generate Mcr::Exe and Push to Dic
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
    class Man < CIAX::Exe
      def initialize(super_cfg, atrb = Hashx.new)
        super
        verbose { 'Initiate Manager (option:' + @opt.keys.join + ')' }
        # id = nil -> taken by ARGV
        # pick already includes :command, :version
        _init_dbi2cfg(%i(sites))
        _init_net
        ___init_stat
        ___init_cmd
        _opt_mode
      end

      private

      def _ext_local
        super
        require 'libmanproc'
        extend(Processor).ext_local_processor
      end

      # Overridden by libmansh
      def _ext_local_shell
        super
        @cobj.loc.add_view
        @cfg[:output] = RecView.new(@stat)
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
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cehlnr') do |cfg|
        Man.new(cfg, Atrb.new(cfg)).shell
      end
    end
  end
end
