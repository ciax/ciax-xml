#!/usr/bin/ruby
require 'libexe'
require 'libmcrcmd'
require 'librecview'
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
        @stat = type?(@cfg[:rec_arc], RecArc)
        @sv_stat = (@cfg[:sv_stat] ||= Prompt.new(@id, @opt))
        ___init_cmd
        _opt_mode
      end

      private

      # Mode Extention by Option
      def _ext_local_test
        @pre_exe_procs << proc { @stat.upd }
        @stat.ext_local
        super
      end

      def _ext_local_shell
        super
        @rec_view = RecView.new(@stat)
        @cfg[:output] = @rec_view
        ___init_page_cmd
        self
      end

      # Initiate for all mode
      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        rem.add_int.add_par(@sv_stat.get(:list))
        rem.add_ext
      end

      def ___init_page_cmd
        page = @cobj.loc.add_page
        page.get('last').def_proc do |ent|
          @rec_view.max += (ent.par[0] || 1).to_i
        end
        page.get('cl').def_proc do
          @rec_view.max = @sv_stat.get(:list).size
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cnr') do |cfg|
        Man.new(cfg).shell
      end
    end
  end
end
