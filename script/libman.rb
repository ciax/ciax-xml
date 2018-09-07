#!/usr/bin/ruby
require 'libexe'
require 'libmcrcmd'
require 'libmanview'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man < Exe
      attr_reader :sub_list # Used for Layer module
      # cfg should have [:dev_list]
      def initialize(super_cfg)
        super(super_cfg)
        verbose { 'Initiate Manager (option:' + @cfg[:opt].keys.join + ')' }
        # id = nil -> taken by ARGV
        @sv_stat = @cfg[:sv_stat]
        @par = Parameter.new(list: @sv_stat.get(:list))
        _init_dbi2cfg(%i())
        _init_net
        @port ||= 55_555
        ___init_cmd
        ___init_stat
      end

      # this is separated for background run
      def run
        @sub_list.run
        _opt_mode
        @mode = 'MCR:' + @mode
        self
      end

      # Mode Extention by Option
      def ext_local_server
        verbose { 'Initiate Record Archive' }
        @cfg[:rec_arc].clear.refresh
        ___mk_cmdlist
        super
      end

      private

      # Initiate for all mode
      def ___init_stat
        @stat = ManView.new(@cfg, @par, @cobj.rem.int.valid_keys)
        @sub_list = @cfg[:dev_list]
      end

      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        rem.add_int.add_par(@par)
        rem.add_ext
        rem.sys.add_item('nonstop', 'Mode')
        rem.sys.add_item('interactive', 'Mode')
      end

      # Making Command List JSON file for WebApp
      def ___mk_cmdlist
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
