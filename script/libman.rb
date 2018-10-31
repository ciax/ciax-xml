#!/usr/bin/ruby
require 'libexe'
require 'libmcrcmd'
require 'libmanview'
require 'libseqlist'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man < Exe
      attr_reader :sub_list # Used for Layer module
      def initialize(super_cfg)
        super(super_cfg)
        verbose { 'Initiate Manager (option:' + @opt.keys.join + ')' }
        # id = nil -> taken by ARGV
        # pick already includes :command, :version
        _init_dbi2cfg(%i(sites))
        _init_net
        ___init_prompt
        ___init_cmd
        ___init_stat
        _opt_mode
      end

      # this is separated for Daemon
      # restart background threads which will be killed by Daemon
      def run
        @sub_list.run
        self
      end

      # Mode Extention by Option
      def ext_local_test
        @stat.ext_local
        super
      end

      def ext_local_driver
        require 'libmanproc'
        ext_local_processor
      end

      def ext_local_server
        verbose { 'Initiate Record Archive' }
        @rec_list.refresh_arc_bg
        ___web_cmdlist
        super
      end

      private

      def ___init_prompt
        @sv_stat = (@cfg[:sv_stat] ||= Prompt.new(@id, @opt))
      end

      # Initiate for all mode
      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        rem.add_int
        rem.add_ext
        @sub_list = @cobj.rem.ext.dev_list
      end

      def ___init_stat
        @rec_list = RecList.new(@id, @sv_stat.get(:list))
        # If rec_list member is increased, current id will be last one
        int = @cobj.rem.int
        @stat = ManView.new(@sv_stat, @rec_list, int.valid_keys)
        int.add_par(@rec_list.par)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cenlrs') do |cfg|
        Man.new(cfg).ext_shell.shell
      end
    end
  end
end
