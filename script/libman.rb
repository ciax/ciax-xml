#!/usr/bin/ruby
require 'libexe'
require 'libmcrcmd'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man < Exe
      attr_reader :sub_list # Used for Layer module
      # cfg should have [:dev_list]
      def initialize(cfg)
        super(Conf.new(cfg))
        verbose { 'Initiate Manager (option:' + @cfg[:opt].keys.join + ')' }
        # id = nil -> taken by ARGV
        ___init_net
        ___init_stat
        ___init_cmd
      end

      # separated for background run
      def run
        @sub_list.run
        _opt_mode
        @mode = 'MCR:' + @mode
        @cfg[:rec_arc].clear.refresh
        self
      end

      # Mode Extention by Option
      def ext_shell
        @cfg[:output] = @stat
        super
      end

      def ext_local_test
        require 'libmandrv'
        super
      end

      def ext_local_driver
        require 'libmandrv'
        super
      end

      def ext_local_server
        verbose { 'Initiate Record List' }
        @cfg[:rec_arc].clear.refresh
        ___mk_cmdlist
        super
      end

      private

      # Initiate for all mode
      def ___init_net
        @id = @cfg[:id]
        @host = @cfg[:host]
        @port = @cfg[:port]
      end

      def ___init_stat
        @stat = @cfg[:rec_arc]
        @sv_stat = @cfg[:sv_stat]
        @sub_list = @cfg[:dev_list]
      end

      def ___init_cmd
        @par = Parameter.new(list: @sv_stat.get(:list))
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
        IO.write(
          vardir('json') + 'mcr_conf.js', 'var config = ' + @cfg[:jlist].to_j
        )
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cenlrs') do |cfg|
        Man.new(cfg).run.ext_shell.shell
      end
    end
  end
end
