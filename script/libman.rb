#!/usr/bin/ruby
require 'libsh'
require 'libseqview'
require 'libmandrv'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man < Exe
      attr_reader :sub_list # Used for Layer module
      # cfg should have [:dev_list]
      def initialize(cfg)
        super(Conf.new(cfg))
        verbose { 'Initiate Layer' }
        # id = nil -> taken by ARGV
        _init_net
        _init_cmd
        _init_stat
      end

      # separated for background run
      def run
        @sub_list.run
        _opt_mode
        @mode = 'MCR:' + @mode
        self
      end

      def ext_shell
        @cfg[:output] = @stat
        extend(Shell).ext_shell
      end

      private

      # Initiate for all mode
      def _init_net
        @id = @cfg[:id]
        @host = @cfg[:host]
        @port = @cfg[:port]
      end

      def _init_cmd
        @cobj.add_rem.cfg[:def_msg] = 'ACCEPT'
        rem = @cobj.rem
        rem.add_sys
        rem.add_int(Int)
        rem.add_ext(Ext)
        rem.sys.add_item('nonstop', 'Mode')
        rem.sys.add_item('interactive', 'Mode')
      end

      def _init_stat
        @par = @cobj.rem.int.ext_par.par
        @stat = List.new
        @sv_stat = @cfg[:sv_stat]
        @sub_list = @cfg[:dev_list]
      end

      # Making Command List JSON file for WebApp
      def _mk_cmdlist
        IO.write(vardir('json') + 'mcr_conf.json', @cfg[:jlist].to_j)
      end

      def ext_client
        @post_exe_procs << proc do
          list = @par.list
          pre = list.size
          list.concat(@sv_stat.get(:list)).uniq!
          post = list.size
          @par.sel(post) if post > pre
        end
        super
      end

      # Initiate for driver
      def ext_local_driver
        super
        extend(ManDrv).ext_local_driver
      end

      def ext_local_test
        super
        extend(ManDrv).ext_local_driver
      end

      def ext_local_server
        super
        @cfg[:rec_list].refresh
        _mk_cmdlist
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', 'cenlrs') do |cfg|
        Man.new(cfg).run.ext_shell.shell
      end
    end
  end
end
