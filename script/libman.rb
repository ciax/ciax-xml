#!/usr/bin/ruby
require 'libexe'
require 'libmcrcmd'
require 'libmanview'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    #  Modes
    #   Remote client  : ext_remote
    #      Access via udp/html
    #   Local client   : ext_local
    #      Access file (read only)
    #   Local processor: ext_local_processor
    #      Access file (R/W)
    #   Local server   : ext_local_server
    #      Command accepts via udp
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
      end

      # this is separated for Daemon
      # restart background threads which will be killed by Daemon
      def run
        _opt_mode
        self
      end

      # Mode Extention by Option
      def ext_local_server
        verbose { 'Initiate Record Archive' }
        @rec_list.ext_server
        ___web_cmdlist
        super
      end

      alias ext_local_driver ext_local_test

      private

      def ___init_prompt
        @sv_stat = (@cfg[:sv_stat] ||= Prompt.new(@id, @opt))
        @par = Parameter.new(list: @sv_stat.get(:list))
      end

      # Initiate for all mode
      def ___init_stat
        @rec_list = RecList.new(@id, @par.list)
        int = @cobj.rem.int
        @stat = ManView.new(@sv_stat, @par, @rec_list, int.valid_keys)
        int.add_par(@par)
      end

      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        rem.add_int
        rem.add_ext
        rem.sys.add_item('nonstop', 'Mode')
        rem.sys.add_item('interactive', 'Mode')
      end

      # Making Command List JSON file for WebApp
      def ___web_cmdlist
        verbose { 'Initiate JS Command List' }
        dbi = @cfg[:dbi]
        jl = Hashx.new(port: @port, commands: dbi.list, label: dbi.label)
        IO.write(vardir('json') + 'mcr_conf.js', 'var config = ' + jl.to_j)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cenlrs') do |cfg|
        Man.new(cfg).run.ext_shell.shell
      end
    end
  end
end
