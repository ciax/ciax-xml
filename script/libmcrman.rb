#!/usr/bin/ruby
require 'libexe'
require 'libmcrcmd'
require 'libreclist'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager/Manipulator
    #  Features
    #   *Test/Driver
    #    -Generate Mcr::Exe and Push to List
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
        ___init_lists
        ___init_cmd
        ___init_stat
        _opt_mode
      end

      # Mode Extention by Option
      def ext_local_test
        @pre_exe_procs << proc { @stat.upd }
        @stat.ext_local
        super
      end

      def ext_shell
        require 'libmcrsh'
        extend(Shell).ext_shell
      end

      private

      def ___init_lists
        @sv_stat = (@cfg[:sv_stat] ||= Prompt.new(@id, @opt))
      end

      # Initiate for all mode
      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        rem.add_int
        rem.add_ext
      end

      def ___init_stat
        int = @cobj.rem.int
        int.add_par(@sv_stat.get(:list))
        @stat = RecList.new(@cfg[:rec_arc], @id, int).ext_view
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cenlrs') do |cfg|
        Man.new(cfg).ext_shell.shell
      end
    end
  end
end
