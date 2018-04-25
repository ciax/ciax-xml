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
        ___init_cmd
        ___init_stat
        ___init_post_exe
      end

      # separated for background run
      def run
        @sub_list.run
        _opt_mode
        @mode = 'MCR:' + @mode
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
        @stat.clear.refresh
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

      def ___init_cmd
        @cobj.add_rem.cfg[:def_msg] = 'ACCEPT'
        rem = @cobj.rem
        rem.add_sys
        rem.add_int
        rem.add_ext
        rem.sys.add_item('nonstop', 'Mode')
        rem.sys.add_item('interactive', 'Mode')
      end

      def ___init_stat
        @stat = @cfg[:rec_list]
        @sv_stat = @cfg[:sv_stat]
        @sub_list = @cfg[:dev_list]
      end

      def ___init_post_exe
        @post_exe_procs << proc do
          @sv_stat.get(:list).each { |id| @par.push(id) }
        end
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
