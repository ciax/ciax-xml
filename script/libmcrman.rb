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
    class Man < Exe
      attr_reader :sub_list # Used for Layer module
      def initialize(super_cfg, &gen_proc)
        super(super_cfg)
        @gen_proc = gen_proc
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

      def ext_local_driver
        require 'libmcrmandrv'
        super
      end

      def ext_local_server
        verbose { 'Initiate Record Archive' }
        Threadx::Fork.new('RecArc', 'mcr', @id) do
          @rec_arc.clear.refresh
        end
        ___web_cmdlist
        super
      end

      def ext_shell
        require 'libmcrsh'
        extend(Shell).ext_shell
      end

      private

      def ___init_lists
        @sv_stat = (@cfg[:sv_stat] ||= Prompt.new(@id, @opt))
        @sub_list = @cfg[:dev_list]
        @rec_arc = @cfg[:rec_arc]
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
        par = int.add_par(@sv_stat.get(:list)).last
        @stat = RecList.new(@cfg[:rec_arc], @id, par, int.valid_keys).ext_view
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cenlrs') do |cfg|
        Man.new(cfg).ext_shell.shell
      end
    end
  end
end
